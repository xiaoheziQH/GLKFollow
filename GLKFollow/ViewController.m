//
//  ViewController.m
//  GLKFollow
//
//  Created by QiuH on 2017/11/10.
//  Copyright © 2017年 QiuH. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import "rotamap.h"
#import <OpenGLES/ES2/glext.h>
#import <AVFoundation/AVFoundation.h>

typedef struct {
    GLKVector4 position;
    GLKVector2 texCoord;
} Vertex;
@interface ViewController ()
{
    GLKMatrix4 _vMatrix;
    GLKMatrix4 _projMatrix;
    GLKMatrix4 _rotaMatrix;
    GLKMatrix4 _mMatrix;
}
@property (nonatomic , strong) EAGLContext* mContext;
@property (nonatomic , strong) GLKBaseEffect* baseEffect;
@property (nonatomic, strong) CMMotionManager * motionManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //新建OpenGLES 上下文
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]; //2.0，还有1.0和3.0
    GLKView* view = (GLKView *)self.view; //storyboard记得添加
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;  //颜色缓冲区格式
    [EAGLContext setCurrentContext:self.mContext];
    
    Vertex vertices[] = {
        {{ 1,  1, 0, 1}, {1, 1}},
        {{-1,  1, 0, 1}, {0, 1}},
        {{ 1, -1, 0, 1}, {1, 0}},
        {{-1, -1, 0, 1}, {0, 0}}
    };

    // Create vertex buffer and fill it with data
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glEnableVertexAttribArray(GLKVertexAttribPosition); //顶点数据缓存
    glVertexAttribPointer(GLKVertexAttribPosition, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, position));

    glEnableVertexAttribArray(GLKVertexAttribTexCoord0); //纹理
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)offsetof(Vertex, texCoord));
    
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[self drawImage:@"radar.png"] options:nil error:nil];
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.texture2d0.enabled = GL_TRUE;
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = GLKTextureTarget2D;
    [self startMotionManager];

}
- (void)update{
    CGRect rect = self.view.frame;
    float height = rect.size.height;
    float width = rect.size.width;
    float f = 2.0 * atanf(0.5);
    float nearX = (3.0e-4f*(float)tan(f/2.0f)*height/width);
    float nearY = nearX * height / width;
    _projMatrix = GLKMatrix4MakeFrustum(-nearX, nearX, -nearY, nearY, 3.0e-4f, 100.0f);
    self.baseEffect.transform.projectionMatrix = _projMatrix;
    
    _vMatrix = GLKMatrix4MakeLookAt(0, 0, -0.2, 0, 0, 1, 0, 1, 0);
    
    _vMatrix = GLKMatrix4Multiply(_rotaMatrix, _vMatrix);
    
    self.baseEffect.transform.modelviewMatrix = _vMatrix;
}
/**
 *  渲染场景代码
 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    //启动着色器
    
    [self.baseEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
}
- (void) startMotionManager {
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    if (!_motionManager.isDeviceMotionAvailable) {
        NSLog(@"_motionManager不可用");
        return;
    }
    [_motionManager startDeviceMotionUpdates];
    _motionManager.deviceMotionUpdateInterval = 1/15.0;
    if (_motionManager.deviceMotionActive) {
        [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
        }];
    } else {
        _motionManager = nil;
    }
}
- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion {
    //四元数
    CMQuaternion quateration = deviceMotion.attitude.quaternion;
    float vertor[5] = {quateration.x,quateration.y,quateration.z,quateration.w,0};
    GLKMatrix4 mm;
    getRotationMatrixFromVector(mm.m, 16, vertor, 5);
    remapCoordinateSystem(mm.m, 1 | 0x80, 2 | 0x80, _rotaMatrix.m);
}

- (CGImageRef )drawImage:(NSString *)fileName {
    UIImage * img = [UIImage imageNamed:fileName];
    CGFloat width = img.size.width;
    CGFloat height = img.size.height;
    UIGraphicsBeginImageContextWithOptions(img.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, width, height);
    
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextClearRect(context, rect);
    
    CGContextDrawImage(context, rect, img.CGImage);
    
    int distance = (int)width/40;
    for (int i = 0; i < width; i += distance) {
        CGFloat cyan[4] = {
            0.9f,0.3f,
            0.4f,1.0f
        };
        CGContextSetStrokeColor(context, cyan);
        CGContextSetLineWidth(context, 1.0f);
        CGPoint aPoints[2];
        aPoints[0] = CGPointMake(i, 0);
        aPoints[1] = CGPointMake(i, width);
        CGContextAddLines(context, aPoints, 2);
        CGContextDrawPath(context, kCGPathStroke);
    }
    for (int i = 0; i < width; i += distance) {
        CGFloat cyan[4] = {
            0.9f,0.3f,
            0.4f,1.0f
        };
        CGContextSetStrokeColor(context, cyan);
        CGContextSetLineWidth(context, 1.0f);
        CGPoint aPoints[2];
        aPoints[0] = CGPointMake(0, i);
        aPoints[1] = CGPointMake(width, i);
        CGContextAddLines(context, aPoints, 2);
        CGContextDrawPath(context, kCGPathStroke);
    }
    
    UIImage * result = UIGraphicsGetImageFromCurrentImageContext();
    
    //    UIImageView * iv = [[UIImageView alloc] initWithImage:result];
    //    iv.frame = rect;
    //    [self.view addSubview:iv];
    //
    UIGraphicsEndImageContext();
    
    return  result.CGImage;
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
