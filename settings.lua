data:extend({
    {
        type = "bool-setting",
        name = "alerts-all-consume-prototypes",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "a"
    },
    {
        type = "bool-setting",
        name = "alerts-all-generic-prototypes",
        setting_type = "runtime-per-user",
        default_value = true,
        order = "b"
    },
    {
        type = "string-setting",
        name = "alerts-whitelist-type",
        setting_type = "runtime-per-user",
        allow_blank = true,
        default_value = "",
        order = "c"
    },
    {
        type = "string-setting",
        name = "alerts-whitelist-name",
        setting_type = "runtime-per-user",
        allow_blank = true,
        default_value = "",
        order = "d"
    },
    {
        type = "string-setting",
        name = "alerts-blacklist-types",
        setting_type = "runtime-per-user",
        allow_blank = true,
        default_value = "",
        order = "e"
    },
    {
        type = "string-setting",
        name = "alerts-blacklist-name",
        setting_type = "runtime-per-user",
        allow_blank = true,
        default_value = "",
        order = "f"
    },
    {
        type = "string-setting",
        name = "alerts-surface",
        setting_type = "runtime-per-user",
        default_value = "alerts-surface-current-surface",
        allowed_values = {"alerts-surface-current-surface", "alerts-surface-all-surfaces"},
        order = "g"
    },
})
