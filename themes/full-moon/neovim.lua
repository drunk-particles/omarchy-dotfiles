return {
	{
		"kdheepak/monochrome.nvim",
		priority = 1000,
		config = function()
			vim.o.background = "light"
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "monochrome",
		},
	},
}