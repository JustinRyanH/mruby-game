# frozen_string_literal: true

namespace :compat do
  desc 'Builds the Compatability Layer for Darwin'
  namespace :darwin do
    task :arm do
      Dir.chdir('./mruby/') do
        sh 'clang -target arm64-darwin -c mruby_compat.c -Ivendor '
        sh 'llvm-ar rc vendor/darwin/arm/libmruby_compat.a mruby_compat.o'
        FileUtils.rm('mruby_compat.o')
      end
    end

    task :amd do
      Dir.chdir('./mruby/') do
        sh 'clang -target x86_64-darwin -c mruby_compat.c -Ivendor'
        sh 'llvm-ar rc vendor/darwin/amd/libmruby_compat.a mruby_compat.o'
        FileUtils.rm('mruby_compat.o')
      end
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
  sh 'odin build . -min-link-libs -debug'
end
