local BasePlugin = require "kong.plugins.base_plugin"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"
local req_set_header = ngx.req.set_header
local ngx_re_gmatch = ngx.re.gmatch

local kong = kong

local TokenToHeaderExtractorHandler = BasePlugin:extend()

TokenToHeaderExtractorHandler.VERSION  = "0.1.0"
-- TokenToHeaderExtractorHandler.PRIORITY = 2

function TokenToHeaderExtractorHandler:new()
    TokenToHeaderExtractorHandler.super.new(self, "token-to-header-extractor")
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function TokenToHeaderExtractorHandler:access(conf)
    -- Eventually, execute the parent implementation
    -- (will log that your plugin is entering this context)
    TokenToHeaderExtractorHandler.super.access(self)
  
    -- Implement any custom logic here
    local log_errors = conf.log_errors
    
    for entity, err in kong.db.token_to_header_extractor:each(100) do
        if err then
            kong.log.debug("Error when iterating over token to header extractor credentials: " .. err)
            return nil
        end

        kong.log.debug("Token Name: " .. entity.token_name)                                               
        kong.log.debug("Headers: " .. dump(ngx.req.get_headers()))                                              
        local header = ngx.req.get_headers()[entity.token_name];                                    
        if header then                      
            kong.log.debug("Raw Token: " .. header)
            local re_gmatch = ngx.re.gmatch  
            local iterator, iter_err = re_gmatch(header, "\\s*[Bb]earer\\s+(.+)")
            if not iterator then
              kong.log.err(iter_err)
              break
            end

            local m, err = iterator()
            if err then
              kong.log.err(err)
              break
            end

            if m and #m > 0 then
              local token = m[1]
                                                    
              kong.log.debug("Token: " .. token)  
              local jwt, err = jwt_decoder:new(token)
              local claims = jwt.claims
              for claim_key, claim_value in pairs(claims) do
                  if entity.token_value_name == claim_key then
                      -- set header
                      req_set_header(entity.header_name, claim_value)
                  end
          
              end
            end  
        end
    end

end

return TokenToHeaderExtractorHandler