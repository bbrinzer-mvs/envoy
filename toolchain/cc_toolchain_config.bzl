load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "tool_path",
)

all_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.assemble,
]

all_link_actions = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]

tool_paths = [
    tool_path(
        name = "gcc",
        path = "/usr/bin/clang-14",
    ),
    tool_path(
        name = "ld",
        path = "/usr/bin/ld.lld-14",
    ),
    tool_path(
        name = "ar",
        path = "/usr/bin/llvm-ar-14",
    ),
    tool_path(
        name = "cpp",
        path = "/usr/bin/clang-cpp-14",
    ),
    tool_path(
        name = "gcov",
        path = "/usr/bin/llvm-cov-14",
    ),
    tool_path(
        name = "nm",
        path = "/usr/bin/llvm-nm-14",
    ),
    tool_path(
        name = "objdump",
        path = "/usr/bin/llvm-objdump-14",
    ),
    tool_path(
        name = "strip",
        path = "/usr/bin/llvm-strip-14",
    ),
    tool_path(
        name = "dwp",
        path = "/usr/bin/llvm-dwp-14",
    ),
]

default_linker_flags = feature(
    name = "default_linker_flags",
    enabled = True,
    flag_sets = [
        flag_set(
            actions = all_link_actions,
            flag_groups = ([flag_group(flags = ["-lstdc++", "-lm", "-lrt"])]),
        ),
    ],
)

def _impl(ctx):
    # FIXME(wbrinzer): Need to get this more robustly than by hard-coding the patch
    # level.
    clang_include = "/usr/lib/llvm-14/lib/clang/14.0.6/include"

    # Cross-compilation target.
    clang_target = ctx.attr.target_cpu + "-linux-gnu"

    features = [
        default_linker_flags,
    ]
    if ctx.attr.cross:
        # Set -target on Clang when cross-compiling.
        features.append(feature(
            name = ctx.attr.target_cpu + "_target_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = all_compile_actions + all_link_actions,
                    flag_groups = ([flag_group(flags = ["-target", clang_target])]),
                ),
            ],
        ))

    cxx_builtin_include_directories = [
        clang_include,
    ]

    if ctx.attr.cross:
        cxx_builtin_include_directories.append("/usr/%s/include" % clang_target)
    else:
        cxx_builtin_include_directories.append("/usr/include")

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = "local",
        host_system_name = "local",
        target_system_name = "local",
        target_cpu = ctx.attr.target_cpu,
        target_libc = "unknown",
        compiler = "clang",
        abi_version = "unknown",
        abi_libc_version = "unknown",
        tool_paths = tool_paths,
        cxx_builtin_include_directories = cxx_builtin_include_directories,
        features = features,
    )

cc_toolchain_config = rule(
    implementation = _impl,
    attrs = {
        "target_cpu": attr.string(),
        "cross": attr.bool()
    },
    provides = [CcToolchainConfigInfo],
)
