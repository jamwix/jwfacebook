rm -rf "obj"
echo "compiling for iphonesim"
haxelib run hxcpp Build.xml -Diphonesim -DHXCPP_CLANG -DOBJC_ARC
echo "compiling for armv6"
haxelib run hxcpp Build.xml -Diphoneos -DHXCPP_CLANG -DOBJC_ARC
echo "compiling for armv7"
haxelib run hxcpp Build.xml -Diphoneos -DHXCPP_ARMV7 -DHXCPP_CLANG -DOBJC_ARC
echo "compiling for arm64"
haxelib run hxcpp Build.xml -Diphoneos -DHXCPP_ARM64 -DHXCPP_CLANG -DOBJC_ARC
echo "Done ! \n"
