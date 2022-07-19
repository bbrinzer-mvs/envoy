package(default_visibility = ["//visibility:public"])

load(":cc_toolchain_config.bzl", "cc_toolchain_config")

# Try to figure out whether we are cross building.
#
# FIXME(wbrinzer): This should actually be querying the execution environment, not the
# host environment, but I don't know how to do that.
config_setting(
    name = "host_aarch64",
    values = {"host_cpu": "aarch64"},
)

config_setting(
    name = "host_x86_64",
    values = {"host_cpu": "k8"},
)

# Dummy file group for fields we aren't populating.
filegroup(name = "empty")

cc_toolchain(
    name = "k8_toolchain",
    toolchain_identifier = "k8-toolchain",
    toolchain_config = ":k8_toolchain_config",
    all_files = ":empty",
    compiler_files = ":empty",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 0,
)
cc_toolchain_config(
    name = "k8_toolchain_config",
    target_cpu = "x86_64",
    cross = select({
        ":host_x86_64": False,
        ":host_aarch64": True,
    })
)

cc_toolchain(
    name = "aarch64_toolchain",
    toolchain_identifier = "aarch64-toolchain",
    toolchain_config = ":aarch64_toolchain_config",
    all_files = ":empty",
    compiler_files = ":empty",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 0,
)
cc_toolchain_config(
    name = "aarch64_toolchain_config",
    target_cpu = "aarch64",
    cross = select({
        ":host_x86_64": True,
        ":host_aarch64": False,
    })
)

cc_toolchain_suite(
    name = "clang_toolchain",
    toolchains = {
        "k8": ":k8_toolchain",
        "aarch64": ":aarch64_toolchain",
    },
)
