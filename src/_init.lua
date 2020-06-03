local index = node.flashindex

local lfs_t = {
  __index = function(_, name)
      local fn_ut, ba, ma, size, modules = index(name)
      if not ba then
        return fn_ut
      elseif name == '_time' then
        return fn_ut
      elseif name == '_config' then
        local fs_ma, fs_size = file.fscfg()
        return {lfs_base = ba, lfs_mapped = ma, lfs_size = size,
                fs_mapped = fs_ma, fs_size = fs_size}
      elseif name == '_list' then
        return modules
      else
        return nil
      end
    end,

  __newindex = function(_, name, value) -- luacheck: no unused
      error("LFS is readonly. Invalid write to LFS." .. name, 2)
    end,

  }

local G=getfenv()
G.LFS = setmetatable(lfs_t,lfs_t)

package.loaders[3] = function(module) -- loader_flash
  local fn, ba = index(module)
  return ba and "Module not in LFS" or fn
end

G.module       = nil    -- disable Lua 5.0 style modules to save RAM
package.seeall = nil

local lf, df = loadfile, dofile
G.loadfile = function(n)
  local mod, ext = n:match("(.*)%.(l[uc]a?)");
  local fn, ba   = index(mod)
  if ba or (ext ~= 'lc' and ext ~= 'lua') then return lf(n) else return fn end
end

G.dofile = function(n)
  local mod, ext = n:match("(.*)%.(l[uc]a?)");
  local fn, ba   = index(mod)
  if ba or (ext ~= 'lc' and ext ~= 'lua') then return df(n) else return fn() end
end
