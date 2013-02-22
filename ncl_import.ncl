;------------------------------------------------------------------------------
;     This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;------------------------------------------------------------------------------

; Please set NCL_DEF_SCRIPTS_DIR to the directory that contains this program
; so that it will be loaded automatically every time ncl is run.

; Code starts here
;_____________________________________________________________________________
; Function: set_def_scripts_dirs
; Doc: set NCL_USER_SCRIPT_DIRS variable with standard ncl library directories.
;     Respect if environmental variable is set already.
;_____________________________________________________________________________
undef("set_def_scripts_dirs")
function set_def_scripts_dirs()
local std_libraries, env, env_len, NCL_USER_SCRIPT_DIRS

begin
  std_libraries = (/"$NCARG_ROOT/lib/ncarg/nclscripts/csm/", \
                    "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/", \
                    "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/"/)

  env = getenv("NCL_USER_SCRIPT_DIRS")

  if ( .not. ismissing(env) ) then
    env_len = str_fields_count(env,":")
    NCL_USER_SCRIPT_DIRS = new(env_len + 3,string)
    do it = 1, env_len, 1
      NCL_USER_SCRIPT_DIRS(it - 1) = str_get_field(env,it,":")
    end do

    do it = env_len, dimsizes(NCL_USER_SCRIPT_DIRS) - 1, 1
      NCL_USER_SCRIPT_DIRS(it) = std_libraries(it - env_len)
    end do
  return(NCL_USER_SCRIPT_DIRS)
  else
    return(std_libraries)
  end if
end

NCL_USER_SCRIPT_DIRS  = set_def_scripts_dirs()
IMPORTED_SCRIPTS = (/"ncl_import"/)

; push an script to IMPORTED_SCRIPTS
undef("push_script")
procedure push_script(script[1]:string)
local array
begin
  array = new(dimsizes(IMPORTED_SCRIPTS) + 1, string)
  array(1:) = IMPORTED_SCRIPTS
  array(0) = script
  delete(IMPORTED_SCRIPTS)
  IMPORTED_SCRIPTS = array
  delete(array)
end

; print imported scripts
undef("imported")
procedure imported()
begin
  print("Scripts imported: "+str_join(IMPORTED_SCRIPTS, ", "))
end

; search a file in several directories
undef("search_file")
function search_file(dirs[*]:string, fn[1]:string)
local found, path, i
begin
  found = False
  do i = 0, dimsizes(dirs) - 1
    path = dirs(i) + fn
    if (isfilepresent(path)) then
      found = True
      found@path = path
      break
    end if
  end do
  return(found)
end

; try importing a single script
undef("try_import")
procedure try_import(script[1]:string)
local i, f
begin
  if(script.eq."?".or.script.eq."") then
    print("Avalable scripts:")
    do i = 0, dimsizes(NCL_USER_SCRIPT_DIRS) - 1
      print(str_join(systemfunc("cd " + NCL_USER_SCRIPT_DIRS(i) + \
            "; ls *.ncl|sed 's/\.ncl$//'"), ", "))
    end do
    else if(.not.any(IMPORTED_SCRIPTS .eq. script)) then
      f = search_file(NCL_USER_SCRIPT_DIRS, script + ".ncl")
      if(f) then
        ;print("loading script "+f@path)
        loadscript(f@path)
        push_script(script)
      else
        print("Warning: failed to import " + str_get_dq + script + str_get_dq)
        print("Run import(" + str_get_dq + "?" +str_get_dq + \
              ") to show available scripts")
      end if
    end if
  end if
end

; import one or more predefined scripts
; Note: in case import of multiple scripts once fails due to dependencies,
;       try import scripts one by one
undef("import")
procedure import(script[*]:string)
local i
begin
  do i = 0, dimsizes(script) - 1
    try_import(script(i))
  end do
end
