//
//  LlamaRunner.h
//  uniterra
//
//  Created by Guy Morgan Beals on 10/17/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LlamaRunner : NSObject

- (nullable instancetype)initWithModelPath:(NSString *)modelPath contextSize:(int)contextSize;
- (nullable NSString *)generateResponseForPrompt:(NSString *)prompt
                                     temperature:(float)temperature
                                            topP:(float)topP
                                       maxTokens:(int)maxTokens;
- (void)cleanup;

@end

NS_ASSUME_NONNULL_END
