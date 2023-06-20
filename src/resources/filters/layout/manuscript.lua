-- manuscript.lua
-- Copyright (C) 2021-2022 Posit Software, PBC

local constants = require("modules/constants")
local kUnrollMarkdownCells = "unroll-markdown-cells"

function manuscriptUnroll() 
  local unrollMdCells = param(kUnrollMarkdownCells, false)
  if unrollMdCells then
    return {
      -- Process any cells that originated from notebooks
      Div = function(divEl)   
          -- If this is a markdown cell, we may need to unroll it
          if divEl.classes:includes("cell") and divEl.classes:includes("markdown") then
            local blocks = pandoc.List()
            for _, childBlock in ipairs(divEl.content) do
              if childBlock.t == "Div" then
                if fnSkip and not fnSkip(divEl) then
                  blocks:insert(childBlock)
                else
                  tappend(blocks, childBlock.content)
                end
              else
                blocks:insert(childBlock)
              end
            end
            return blocks
          end        
        end
      }
  else
    return {}
  end
end

function manuscript() 

  if _quarto.format.isWordProcessorOutput() or _quarto.format.isLatexOutput() then

    local language = param("language", nil);
    local notebookPrefix = language[constants.kLangSourcePrefix]
    
    local manuscriptBaseUrl = param(constants.kManuscriptUrl)
    local notebookLinks = param(constants.kNotebookLinks)

    return {

      -- Process any cells that originated from notebooks
      Div = function(divEl)        

        -- Don't process these specially unless 'inline' links
        -- are enabled
        if (notebookLinks == false or notebookLinks == "global") then
          return
        end        

        local nbPath = divEl.attributes[constants.kNotebook]
        local nbTitle = divEl.attributes[constants.kNotebookTitle]
        if manuscriptBaseUrl ~= nil and nbPath == nil then
          -- if this is a computational cell, synthesize the nbPath
          if divEl.classes:includes("cell") then
            local relativeInputPath = pandoc.path.make_relative(quarto.doc.input_file, quarto.project.directory)
            nbPath = relativeInputPath
            nbTitle = language['article-notebook-label']
          end
        end

        if manuscriptBaseUrl ~= nil and nbPath ~= nil then
          
          -- Provide preview path for the preview generator - this
          -- will specify a preview file name to use when generating this preview
          -- 
          -- NOTE: This is a point of coordinate where the name of the notebooks is important
          -- and this is relying upon that name being present in order to form these links
          --
          -- TODO: Make the filter params include notebook-context information that
          -- can be used to resolve links (if they are present)
          local nbFileName = pandoc.path.filename(nbPath)
          local nbDir = pandoc.path.directory(nbPath)
          if nbDir == "." then
            nbDir = ""
          end
          local previewFile = nbFileName .. ".html"
          local previewPath = pandoc.path.join({nbDir, previewFile})

          -- The title for the notebook
          if nbTitle == nil then
            nbTitle = nbFileName
          end

          -- The Id
          local cellId = divEl.attributes[constants.kNotebookCellId];
          if cellId ~= nil then
            cellId = '#' .. cellId
          else
            cellId = ''
          end
        

          -- The label link  
          local notebookUrl
          if manuscriptBaseUrl:sub(-1) ~= '/' then
            notebookUrl =  manuscriptBaseUrl .. '/' .. previewPath .. cellId;
          else
            notebookUrl =  manuscriptBaseUrl .. previewPath .. cellId;
          end

          local labelInlines = pandoc.List({ pandoc.Str(notebookPrefix), pandoc.Str(':'), pandoc.Space(), pandoc.Link(nbTitle, notebookUrl)})

          -- Attempt to forward the link into element captions, when possible
          local resolvedEl = _quarto.ast.walk(divEl, {
            Div = function(el)

              -- Forward to figure div
              if isFigureDiv(el) then
                local last = el.content[#el.content]
                if last and last.t == "Para" and #el.content > 1 then
                  labelInlines:insert(1, pandoc.Space())
                  tappend(last.content, labelInlines)  
                else
                  return nil
                end
                return el
              end
            end,
        
            -- Forward to figure image
            Para = function(el)
              local image = discoverFigure(el)
              if image and isFigureImage(image) then
                labelInlines:insert(1, pandoc.Space())
                tappend(image.caption, labelInlines)
                return el
              end
            end,

            -- Forward to tables
            Table = function(el)
              if el.caption then
                labelInlines:insert(1, pandoc.Space())
                tappend(el.caption, labelInlines)
                return el
              end
            end
          })
                    
          if resolvedEl then
            return resolvedEl
          else
            -- FIXME This is unreachable code, walk always returns a new element
            
            -- We couldn't forward to caption, just place inline
            divEl.content:insert(pandoc.Subscript(labelInlines))
            return divEl
          end
        end
      end
    }
  else 
    return {}
  end
end