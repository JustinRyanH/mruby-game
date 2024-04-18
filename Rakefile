# frozen_string_literal: true

namespace :compat do
  desc 'Builds the Compatability Layer for Darwin'
  task :darwin do
    Dir.chdir('./mruby/') do
      sh 'clang -c mruby_compat.c -Ivendor'
      sh 'llvm-ar rc vendor/darwin/libmruby_compat.a mruby_compat.o'
      FileUtils.rm('mruby_compat.o')
    end
  end

  desc 'Builds the Compatability Layer for Windows'
  task :windows do
    Dir.chdir('./mruby/') do
      sh 'cl /nologo /c /EHsc .\mruby_compat.c /IVendor'
      sh 'lib /nologo mruby_compat.obj'
      FileUtils.rm('mruby_compat.obj')
      FileUtils.mv('mruby_compat.lib', './vendor/windows')
    end
  end
end

desc 'Builds the EXE'
task :build do
  sh 'odin build . -min-link-libs'
end
