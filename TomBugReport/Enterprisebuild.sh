#!/bin/sh -vx
#author by 得力 https://github.com/qindeli/WorksapceShell
#注意：脚本和WorkSpace必须在同一个目录
#工程名字(Target名字)
Project_Name="TomBugReport"
#xcodeproj的名字
Xcodeproj_Name="TomBugReport"
#Bundle ID
AppBundleID="coding.tom.TomBugReport"
#配置环境，Release或者Debug,默认release
Configuration="Release"
#IPA存放的地址
IPA_Save_Path="/Users/${USER}/Desktop/${Project_Name}"_$(date +%H%M%S)

EnterpriseExportOptionsPlist=./EnterprisePlist.plist
EnterpriseExportOptionsPlist=${EnterpriseExportOptionsPlist}

# 证书名 和 描述文件
EN_CODE_SIGN_IDENTITY="iPhone Distribution: Chemi Technologies(Beijing)Co.,ltd"
PROVISIONING_PROFILE_NAME="/Users/${USER}/Project/mobileprovision/Che_Mi_All_In_House.mobileprovision"

# 打包并导出IPA
xcodebuild -project $Xcodeproj_Name.xcodeproj -scheme $Project_Name -configuration $Configuration -archivePath build/$Project_Name-build.xcarchive archive build CODE_SIGN_IDENTITY="${EN_CODE_SIGN_IDENTITY}" PROVISIONING_PROFILE="${PROVISIONING_PROFILE_NAME}" PRODUCT_BUNDLE_IDENTIFIER="${AppBundleID}"
xcodebuild -exportArchive -archivePath build/$Project_Name-build.xcarchive -exportOptionsPlist ${EnterpriseExportOptionsPlist} -exportPath $IPA_Save_Path 

curl -F "file=@${IPA_Save_Path}/${Project_Name}.ipa" -F "uKey=e8f08b4a3f2173ce206178947637c6c3" -F "_api_key=bf6ad80a3321b4d3216fd2db6cf5d289" https://qiniu-storage.pgyer.com/apiv1/app/upload

rm -rf build