return {
    {
        "bjarneo/aether.nvim",
        branch = "v2",
        name = "aether",
        priority = 1000,
        opts = {
            transparent = false,
            colors = {
                -- Background colors
                bg = "#192423",
                bg_dark = "#192423",
                bg_highlight = "#628481",

                -- Foreground colors
                -- fg: Object properties, builtin types, builtin variables, member access, default text
                fg = "#f1f4f3",
                -- fg_dark: Inactive elements, statusline, secondary text
                fg_dark = "#d8e3e2",
                -- comment: Line highlight, gutter elements, disabled states
                comment = "#628481",

                -- Accent colors
                -- red: Errors, diagnostics, tags, deletions, breakpoints
                red = "#59c082",
                -- orange: Constants, numbers, current line number, git modifications
                orange = "#82d9a5",
                -- yellow: Types, classes, constructors, warnings, numbers, booleans
                yellow = "#77cfb8",
                -- green: Comments, strings, success states, git additions
                green = "#6acda2",
                -- cyan: Parameters, regex, preprocessor, hints, properties
                cyan = "#6aa5cd",
                -- blue: Functions, keywords, directories, links, info diagnostics
                blue = "#68c8cf",
                -- purple: Storage keywords, special keywords, identifiers, namespaces
                purple = "#8fc6d6",
                -- magenta: Function declarations, exception handling, tags
                magenta = "#d1e9f0",
            },
        },
        config = function(_, opts)
            require("aether").setup(opts)
            vim.cmd.colorscheme("aether")

            -- Enable hot reload
            require("aether.hotreload").setup()
        end,
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "aether",
        },
    },
}
