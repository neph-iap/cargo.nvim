local public = {}

local cache = { crates = {}, pages = {} }

local function has_crate(name)
	return cache.crates[name] ~= nil
end

---@param page_number integer
local function search_page(page_number)
	if vim.tbl_contains(cache.pages, page_number) then
		return
	end

	-- io.popen just doesn't work for some reason; it returns like 10 results instead of 100.
	-- I've previously had issues with io.popen on other projects as well and always found
	-- os.execute to correctly do what I need. Contrary to popular belief, it seems io.popen
	-- and os.execute actually behave very differently, and I would recommend sticking to
	-- os.execute for this kind of thing.
	os.execute(
		"curl -s 'https://crates.io/api/v1/crates?sort=downloads&page="
			.. page_number
			.. "&per_page=100' > '"
			.. vim.fn.stdpath("data")
			.. "/cargo-temp.json'"
	)

	local file = assert(io.open(vim.fn.stdpath("data") .. "/cargo-temp.json"))
	local html = file:read("*a")
	file:close()

	local json = vim.fn.json_decode(html) or { crates = {} }

	vim.print(json)

	for _, crate in ipairs(json.crates) do
		vim.print("Checking crate " .. crate.id .. "...")
		if not has_crate(crate.id) then
			vim.print("Adding crate " .. crate.id .. "...")
			cache.crates[crate.id] = crate
		end
	end

	table.insert(cache.pages, page_number)
end

function public.load_cache()
	local cache_file = io.open(vim.fn.stdpath("data") .. "/cargo-cache.json")
	if cache_file then
		local cache_string = cache_file:read("*a")
		if cache_string ~= "" then
			local cache_json = vim.fn.json_decode(cache_string)
			if cache_json then
				cache = cache_json
			end
		end
	end

	for page_number = 1, 100 do
		search_page(page_number)
	end

	public.save_cache()
end

function public.save_cache()
	local cache_file = assert(io.open(vim.fn.stdpath("data") .. "/cargo-cache.json", "w"))
	cache_file:write(vim.fn.json_encode(cache))
	cache_file:close()
end

function public.get_crates()
	return cache.crates
end

function public.get_crate_names()
	local crate_names = {}

	for name, crate in pairs(cache.crates) do
		table.insert(crate_names, { name = name, downloads = crate.downloads })
	end

	table.sort(crate_names, function(a, b)
		return a.downloads > b.downloads
	end)

	local just_names = {}
	for _, crate in ipairs(crate_names) do
		table.insert(just_names, crate.name)
	end

	return just_names
end

return public
