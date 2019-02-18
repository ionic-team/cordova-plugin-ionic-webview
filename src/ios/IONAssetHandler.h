#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface IONAssetHandler : NSObject <WKURLSchemeHandler>

@property (nonatomic, strong) NSString * basePath;
@property (nonatomic, strong) NSString * scheme;

-(void)setAssetPath:(NSString *)assetPath;
- (instancetype)initWithBasePath:(NSString *)basePath andScheme:(NSString *)scheme;


@end
