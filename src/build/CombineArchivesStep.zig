//! Combines multiple static archives into a single fat archive.
//! Uses a cross-platform MRI-script build tool on every platform.
const std = @import("std");

/// Combine multiple static archives into a single fat archive.
///
/// `name` identifies the library (e.g. "ghostty-internal", "ghostty-vt").
/// Output uses a `-fat` suffix to distinguish the combined archive from
/// the single-library archive in the build cache.
pub fn create(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    name: []const u8,
    sources: []const std.Build.LazyPath,
) struct { step: *std.Build.Step, output: std.Build.LazyPath } {
    // Generate an MRI script and pipe it to `zig ar -M`. This accepts
    // duplicate archive-member basenames that Apple libtool rejects, and it
    // works on every host platform without relying on /bin/sh.
    const tool = b.addExecutable(.{
        .name = "combine_archives",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/build/combine_archives.zig"),
            .target = b.graph.host,
        }),
    });
    const run = b.addRunArtifact(tool);
    run.addArg(b.graph.zig_exe);
    const out_name = if (target.result.os.tag == .windows)
        b.fmt("{s}-fat.lib", .{name})
    else
        b.fmt("lib{s}-fat.a", .{name});
    const output = run.addOutputFileArg(out_name);
    for (sources) |source| run.addFileArg(source);

    return .{ .step = &run.step, .output = output };
}
