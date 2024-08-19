-- usecell.lua
-- Copyright (C) 2020-2024 Posit Software, PBC

function use_cell_filter()
  local ids_used = {}
  local divs = {}
  local spans = {}

  return {
    Pandoc = function(doc)
      _quarto.ast.walk(doc.blocks, {
        RawInline = function(el)
          if el.format ~= "quarto-internal" then
            return
          end
          if not pcall(function() 
            local data = quarto.json.decode(el.text)
            if data.type == "use-cell" then
              ids_used[data.payload.id] = true
            end
          end) then
            warn("[Malformed document] Failed to decode quarto-internal JSON: " .. el.text)
          end
        end
      })
      doc.blocks = _quarto.ast.walk(doc.blocks, {
        Div = function(el)
          if not ids_used[el.attr.identifier] then
            return nil
          end
          divs[el.attr.identifier] = el
          return {}
        end,
        Span = function(el)
          if not ids_used[el.attr.identifier] then
            return nil
          end
          spans[el.attr.identifier] = el
          return {}
        end
      })

      local handle_block = function(el)
        if #el.content ~= 1 then
          return nil
        end
        local raw = quarto.utils.match("[1]/RawInline")(el)
        if raw == nil then
          return nil
        end
        local result, data = pcall(function() 
          local data = quarto.json.decode(raw.text)
          if data.type == "use-cell" then
            return data.payload.id
          end
          return false
        end)
        if data == false then
          return nil
        end
        if not result or data == nil then
          warn("[Malformed document] Failed to decode quarto-internal JSON: \n" .. data .. "\n. Removing from document.")
          return {}
        end
        local div = divs[data]
        if div == nil then
          warn(
            "[Malformed document] Found `use-cell` without a corresponding div with id: " .. tostring(data) .. ".\n" ..
            "This might happen because this `use-cell` is used in div context, while the id corresponds to a span.\n" ..
            "Removing from document.")
          return {}
        end
        return div
      end
      -- replace div-context use-cells
      doc.blocks = _quarto.ast.walk(doc.blocks, {
        Para = handle_block,
        Plain = handle_block
      })
      -- replace span-context use-cells
      doc.blocks = _quarto.ast.walk(doc.blocks, {
        RawInline = function(el)
          if el.format ~= "quarto-internal" then
            return
          end
          local result, data = pcall(function() 
            local data = quarto.json.decode(el.text)
            if data.type == "use-cell" then
              return spans[data.payload.id]
            end
          end)
          if not result then
            warn("[Malformed document] Failed to decode quarto-internal JSON: \n" .. el.text .. "\n. Removing from document.")
            return {}
          end
          if data == nil then
            warn(
              "[Malformed document] Found `use-cell` without a corresponding span with id: " .. el.text .. ".\n" ..
              "This might happen because this `use-cell` is used in span context, while the id corresponds to a div.\n" ..
              "Removing from document.")
            return {}
          end
          return data
        end        
      })

      -- TODO: text-context?
      return doc
    end
  }
end
