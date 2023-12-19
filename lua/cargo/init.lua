local public = {}

local cache = require("cargo.cache")

function public.setup()
	cache.load_cache()

	vim.api.nvim_create_user_command("AddCrate", function()
		vim.ui.select(cache.get_crate_names(), {
			prompt = "Add Crate:",
			kind = "cargo",
		}, function(choice)
			vim.print(vim.fn.system("cargo add " .. choice))
		end)
	end, {})
end

return public
