-- qmd-reader.lua
-- A Pandoc reader for Quarto Markdown
-- 
-- Copyright (C) 2023 by RStudio, PBC
--
-- Originally by Albert Krewinkel

local md_shortcode = require("lpegshortcode")

-- Support the same format extensions as pandoc's Markdown reader
Extensions = pandoc.format.extensions 'markdown'

-- we replace invalid tags with random strings of the same size
-- to safely allow code blocks inside pipe tables
-- note that we can't use uppercase letters here
-- because pandoc canonicalizes classes to lowercase.
function random_string(size)
  local chars = "abcdefghijklmnopqrstuvwxyz"
  local lst = {}
  for _ = 1,size do
    local ix = math.random(1, #chars)
    table.insert(lst, string.sub(chars, ix, ix))
  end
  return table.concat(lst, "")
end

function find_invalid_tags(str)
  -- [^.=\n]
  --   we disallow "." to avoid catching {.python}
  --   we disallow "=" to avoid catching {foo="bar"}
  --   we disallow "\n" to avoid multiple lines

  -- no | in lua patterns...

  -- (c standard, 7.4.1.10, isspace function)
  -- %s catches \n and \r, so we must use [ \t\f\v] instead

  local patterns = {
    "^[ \t\f\v]*(```+[ \t\f\v]*)(%{+[^.=\n\r]*%}+)", 
    "\n[ \t\f\v]*(```+[ \t\f\v]*)(%{+[^.=\n\r]+%}+)"
  }
  local function find_it(init)
    for _, pattern in ipairs(patterns) do
      local range_start, range_end, ticks, tag = str:find(pattern, init)
      if range_start ~= nil then
        return range_start, range_end, ticks, tag
      end
    end
    return nil
  end

  local init = 1
  local range_start, range_end, ticks, tag = find_it(init)
  local tag_set = {}
  local tags = {}
  while tag ~= nil do
    init = range_end + 1
    if not tag_set[tag] then
      tag_set[tag] = true
      table.insert(tags, tag)
    end
    range_start, range_end, ticks, tag = find_it(init)
  end
  return tags
end

function escape_invalid_tags(str)
  local tags = find_invalid_tags(str)
  -- we must now replace the tags in a careful order. Specifically,
  -- we can't replace a key that's a substring of a larger key without
  -- first replacing the larger key.
  --
  -- ie. if we replace {python} before {{python}}, Bad Things Happen.
  -- so we sort the tags by descending size, which suffices
  table.sort(tags, function(a, b) return #b < #a end)

  local replacements = {}
  for _, k in ipairs(tags) do
    local replacement
    local attempts = 1
    repeat
      replacement = random_string(#k)
      attempts = attempts + 1
    until str:find(replacement, 1, true) == nil or attempts == 100
    if attempts == 100 then
      print("Internal error, could not find safe replacement for "..k.." after 100 tries")
      print("Please file a bug at https://github.com/quarto-dev/quarto-cli")
      os.exit(1)
    end
    -- replace all lua special pattern characters with their
    -- escaped versions
    local safe_pattern = k:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    replacements[replacement] = k
    local patterns = {
      "^([ \t\f\v]*```+[ \t\f\v]*)" .. safe_pattern,
      "(\n[ \t\f\v]*```+[ \t\f\v]*)" .. safe_pattern
    }

    str = str:gsub(patterns[1], "%1" .. replacement):gsub(patterns[2], "%1" .. replacement)
  end
  return str, replacements
end

function unescape_invalid_tags(str, tags)
  for replacement, k in pairs(tags) do
    -- replace all lua special replacement characters with their
    -- escaped versions, so that when we restore the behavior,
    -- we don't accidentally create a pattern
    local result = k:gsub("([$%%])", "%%%1")
    str = str:gsub(replacement, result)
  end
  return str
end

function parse_shortcodes(txt)
  return md_shortcode.md_shortcode:match(txt)
end

function urldecode(url)
  if url == nil then
    return
  end
    url = url:gsub("+", " ")
    url = url:gsub("%%(%x%x)", function(x)
      return string.char(tonumber(x, 16))
    end)
    url = url:gsub('%&quot%;', '"')
  return url
end

function Reader (inputs, opts)
  local txt, tags = escape_invalid_tags(tostring(inputs))
  txt = parse_shortcodes(txt)

  local flavor = {
    format = "markdown",
    extensions = {},
  }
  if param("user-defined-from") then
    flavor = _quarto.format.parse_format(param("user-defined-from"))
  else 
    for k, v in pairs(opts.extensions) do
      flavor.extensions[v] = true
    end
  end

  -- Format flavor, i.e., which extensions should be enabled/disabled.
  local function restore_invalid_tags(tag)
    return tags[tag] or tag
  end

  -- parse_shortcode overparses shortcodes inside code blocks, link targets, etc.
  -- so we need to undo that damage here

  local unshortcode_text = function (c)
    c.text = md_shortcode.unshortcode:match(c.text)
    return c
  end

  local doc = pandoc.read(txt, flavor, opts):walk {
    CodeBlock = function (cb)
      cb.classes = cb.classes:map(restore_invalid_tags)
      cb.text = md_shortcode.unshortcode:match(cb.text)
      cb.text = unescape_invalid_tags(cb.text, tags)
      return cb
    end,
    Code = unshortcode_text,
    RawInline = unshortcode_text,
    RawBlock = unshortcode_text,
    Link = function (l)
      local result = md_shortcode.unshortcode:match(urldecode(l.target))
      l.target = result
      return l
    end,
    Image = function (i)
      i.src = md_shortcode.unshortcode:match(urldecode(i.src))
      return i
    end,
  }
  return doc
end