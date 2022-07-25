load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "feature",
    "flag_group",
    "flag_set",
    "tool_path",
    "with_feature_set",
)

all_compile_actions = [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.clif_match,
    ACTION_NAMES.lto_backend,
]

all_cpp_compile_actions = [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.clif_match,
]

all_link_actions = [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]

tool_paths = [
    tool_path(name="gcc", path="/usr/bin/clang-14"),
    tool_path(name="ld", path="/usr/bin/ld.lld-14"),
    tool_path(name="ar", path="/usr/bin/llvm-ar-14"),
    tool_path(name="cpp", path="/usr/bin/clang-cpp-14"),
    tool_path(name="gcov", path="/usr/bin/llvm-cov-14"),
    tool_path(name="nm", path="/usr/bin/llvm-nm-14"),
    tool_path(name="objdump", path="/usr/bin/llvm-objdump-14"),
    tool_path(name="strip", path="/usr/bin/llvm-strip-14"),
    tool_path(name="dwp", path="/usr/bin/llvm-dwp-14"),
]

default_linker_flags = feature(
    name="default_linker_flags",
    enabled=True,
    flag_sets=[
        flag_set(
            actions=all_link_actions,
            flag_groups=([flag_group(flags=["-lstdc++", "-lm", "-lrt"])]),
        )
    ],
)


def _impl(ctx):
    clang_includes = ["/usr/lib/llvm-14/lib/clang", "/usr/lib/clang"]

    # Cross-compilation target.
    clang_target = ctx.attr.target_cpu + "-linux-gnu"

    # We need to define what flags to use for compile modes, e.g., `opt`. Otherwise
    # everything is a debug/non-optimized build by default.
    #
    # XREF: `tools/cpp/bsd_cc_toolchain_config.bzl` in the main Bazel repository.
    #
    # I copied the flags for *BSD because FreeBSD uses Clang as its default system
    # compiler, so these should be reasonably close to correct.

    default_link_flags_feature = feature(
        name="default_link_flags",
        enabled=True,
        flag_sets=[
            flag_set(
                actions=all_link_actions,
                flag_groups=[
                    flag_group(
                        flags=[
                            "-lstdc++",
                            "-lm",
                            "-lrt",
                            "-Wl,-z,relro,-z,now",
                            "-no-canonical-prefixes",
                        ]
                    )
                ],
            ),
            flag_set(
                actions=all_link_actions,
                flag_groups=[flag_group(flags=["-Wl,--gc-sections"])],
                with_features=[with_feature_set(features=["opt"])],
            ),
        ],
    )

    unfiltered_compile_flags_feature = feature(
        name="unfiltered_compile_flags",
        enabled=True,
        flag_sets=[
            flag_set(
                actions=all_compile_actions,
                flag_groups=[
                    flag_group(
                        flags=[
                            "-no-canonical-prefixes",
                            "-Wno-builtin-macro-redefined",
                            '-D__DATE__="redacted"',
                            '-D__TIMESTAMP__="redacted"',
                            '-D__TIME__="redacted"',
                        ]
                    )
                ],
            )
        ],
    )

    supports_pic_feature = feature(name="supports_pic", enabled=True)

    default_compile_flags_feature = feature(
        name="default_compile_flags",
        enabled=True,
        flag_sets=[
            flag_set(
                actions=all_compile_actions,
                flag_groups=[
                    flag_group(
                        flags=[
                            "-U_FORTIFY_SOURCE",
                            "-D_FORTIFY_SOURCE=1",
                            "-fstack-protector",
                            "-Wall",
                            "-fno-omit-frame-pointer",
                        ]
                    )
                ],
            ),
            flag_set(
                actions=all_compile_actions,
                flag_groups=[flag_group(flags=["-g"])],
                with_features=[with_feature_set(features=["dbg"])],
            ),
            flag_set(
                actions=all_compile_actions,
                flag_groups=[
                    flag_group(
                        flags=[
                            "-g0",
                            "-O2",
                            "-DNDEBUG",
                            "-ffunction-sections",
                            "-fdata-sections",
                        ]
                    )
                ],
                with_features=[with_feature_set(features=["opt"])],
            ),
            flag_set(
                actions=all_cpp_compile_actions + [ACTION_NAMES.lto_backend],
                flag_groups=[flag_group(flags=["-std=c++0x"])],
            ),
        ],
    )

    opt_feature = feature(name="opt")

    supports_dynamic_linker_feature = feature(
        name="supports_dynamic_linker", enabled=True
    )

    objcopy_embed_flags_feature = feature(
        name="objcopy_embed_flags",
        enabled=True,
        flag_sets=[
            flag_set(
                actions=["objcopy_embed_data"],
                flag_groups=[flag_group(flags=["-I", "binary"])],
            )
        ],
    )

    dbg_feature = feature(name="dbg")

    user_compile_flags_feature = feature(
        name="user_compile_flags",
        enabled=True,
        flag_sets=[
            flag_set(
                actions=all_compile_actions,
                flag_groups=[
                    flag_group(
                        flags=["%{user_compile_flags}"],
                        iterate_over="user_compile_flags",
                        expand_if_available="user_compile_flags",
                    )
                ],
            )
        ],
    )

    sysroot_feature = feature(
        name="sysroot",
        enabled=True,
        flag_sets=[
            flag_set(
                actions=[
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.clif_match,
                    ACTION_NAMES.lto_backend,
                ]
                + all_link_actions,
                flag_groups=[
                    flag_group(
                        flags=["--sysroot=%{sysroot}"], expand_if_available="sysroot"
                    )
                ],
            )
        ],
    )

    features = [
        default_compile_flags_feature,
        default_link_flags_feature,
        supports_dynamic_linker_feature,
        supports_pic_feature,
        objcopy_embed_flags_feature,
        opt_feature,
        dbg_feature,
        user_compile_flags_feature,
        sysroot_feature,
        unfiltered_compile_flags_feature,
    ]

    if ctx.attr.cross:
        # Set -target on Clang when cross-compiling.
        features.append(
            feature(
                name=ctx.attr.target_cpu + "_target_flags",
                enabled=True,
                flag_sets=[
                    flag_set(
                        actions=all_compile_actions + all_link_actions,
                        flag_groups=([flag_group(flags=["-target", clang_target])]),
                    )
                ],
            )
        )

    cxx_builtin_include_directories = clang_includes

    if ctx.attr.cross:
        cxx_builtin_include_directories.append("/usr/%s/include" % clang_target)
    else:
        cxx_builtin_include_directories.append("/usr/include")

    return cc_common.create_cc_toolchain_config_info(
        ctx=ctx,
        toolchain_identifier="local",
        host_system_name="local",
        target_system_name="local",
        target_cpu=ctx.attr.target_cpu,
        target_libc="unknown",
        compiler="clang",
        abi_version="unknown",
        abi_libc_version="unknown",
        tool_paths=tool_paths,
        cxx_builtin_include_directories=cxx_builtin_include_directories,
        features=features,
    )


cc_toolchain_config = rule(
    implementation=_impl,
    attrs={"target_cpu": attr.string(), "cross": attr.bool()},
    provides=[CcToolchainConfigInfo],
)
