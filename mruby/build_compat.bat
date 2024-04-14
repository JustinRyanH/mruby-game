cl /nologo /c /EHsc .\mruby_compat.c /IVendor
lib /nologo mruby_compat.obj
del mruby_compat.obj
move mruby_compat.lib ./vendor/windows/
