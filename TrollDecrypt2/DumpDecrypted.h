@interface DumpDecrypted : NSObject {
	char decryptedAppPathStr[PATH_MAX];
	char *filename;
	char *appDirName;
	char *appDirPath;
}

@property (nonatomic,copy) NSString *appPath;
@property (nonatomic,copy) NSString *docPath;
@property (nonatomic,copy) NSString *appName;
@property (nonatomic,copy) NSString *appVersion;

- (id)initWithPathToBinary:(NSString *)pathToBinary appName:(NSString *)appName appVersion:(NSString *)appVersion;
- (void)createIPAFile:(pid_t)pid;
- (BOOL)dumpDecryptedImage:(const struct mach_header *)image_mh fileName:(const char *)encryptedImageFilenameStr image:(int)imageNum task:(vm_map_t)targetTask;
- (NSString *)IPAPath;
@end
