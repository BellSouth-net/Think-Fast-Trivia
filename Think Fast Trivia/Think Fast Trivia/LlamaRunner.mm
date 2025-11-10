//
//  LlamaRunner.mm
//  uniterra
//
//  Created by Guy Morgan Beals on 10/17/25.
//

#import "LlamaRunner.h"
#include "llama-libs/llama.h"
#include "llama-libs/ggml.h"
#include <vector>
#include <string>
#import <sys/utsname.h>

@implementation LlamaRunner {
    llama_model *model;
    llama_context *ctx;
    llama_sampler *sampler;
    int32_t contextSize;  // Store context size for recreation
}

// Helper method to check if device is memory-constrained
// Only iPhone 16 Pro/Pro Max and newer Pro models have enough RAM
+ (BOOL)isMemoryConstrainedDevice {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    // ONLY these models have enough memory for full acceleration:
    // iPhone 16 Pro and Pro Max (and future 17+ Pro models)
    NSArray *highMemoryModels = @[
        @"iPhone17,", // Future iPhone 17 Pro series
        @"iPhone16,", // iPhone 16 Pro (if this is the identifier)
        // Note: We'll need to update these when actual identifiers are known
    ];
    
    for (NSString *model in highMemoryModels) {
        if ([deviceModel hasPrefix:model] || [deviceModel isEqualToString:model]) {
            NSLog(@"🚀 High-memory device detected: %@", deviceModel);
            return NO; // NOT constrained
        }
    }
    
    // Everything else is memory-constrained (including iPhone 15 Pro Max)
    NSLog(@"📱 Detected memory-constrained device: %@", deviceModel);
    return YES; // IS constrained
}

- (instancetype)initWithModelPath:(NSString *)modelPath contextSize:(int)ctxSize {
    self = [super init];
    if (self) {
        NSLog(@"🔥 Initializing llama with model: %@, context: %d", modelPath, ctxSize);
        
        // Store context size for later recreation
        self->contextSize = ctxSize;
        
        // Initialize llama backend ONCE globally (not per-instance)
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            llama_backend_init();
            NSLog(@"✅ llama_backend initialized (one-time global init)");
        });
        
        // Check if we need memory optimizations
        BOOL isConstrained = [[self class] isMemoryConstrainedDevice];
        
        // Model parameters - adjust based on device capabilities
        llama_model_params model_params = llama_model_default_params();
        
        if (isConstrained) {
            // iPhone 15 Pro Max and older: minimal GPU to stay under 4GB
            model_params.n_gpu_layers = 15; // Only offload 15 layers to Metal
            NSLog(@"⚠️ Using minimal GPU layers (15) for memory-constrained device");
        } else {
            // iPhone 16 Pro and newer: use full acceleration
            model_params.n_gpu_layers = 999; // Offload all layers to Metal
            NSLog(@"✅ Using full GPU acceleration (999 layers) - iPhone 16 Pro or newer");
        }
        
        model_params.use_mmap = true;
        model_params.use_mlock = false;
        
        // Load model
        const char *model_path_c = [modelPath UTF8String];
        model = llama_model_load_from_file(model_path_c, model_params);
        
        if (!model) {
            NSLog(@"❌ Failed to load model from: %@", modelPath);
            return nil;
        }
        
        NSLog(@"✅ Model loaded successfully");
        
        // Context parameters - adjust based on device capabilities
        llama_context_params ctx_params = llama_context_default_params();
        ctx_params.n_ctx = ctxSize;
        
        if (isConstrained) {
            // iPhone 14 and older: smaller batch size to save memory
            ctx_params.n_batch = 128;
            NSLog(@"⚠️ Using reduced batch size (128) for memory-constrained device");
        } else {
            // iPhone 15 Pro and newer: larger batch for better performance
            ctx_params.n_batch = 512;
            NSLog(@"✅ Using full batch size (512)");
        }
        
        ctx_params.n_threads = 4;
        
        // Create context
        ctx = llama_init_from_model(model, ctx_params);
        
        if (!ctx) {
            NSLog(@"❌ Failed to create context");
            llama_model_free(model);
            return nil;
        }
        
        NSLog(@"✅ Context created successfully");
        
        // Sampler will be created per generation with specific params
        sampler = nullptr;
        
        NSLog(@"✅ LlamaRunner initialized - Metal should be active!");
    }
    return self;
}

- (nullable NSString *)generateResponseForPrompt:(NSString *)prompt
                                     temperature:(float)temperature
                                            topP:(float)topP
                                       maxTokens:(int)maxTokens {
    if (!model) {
        NSLog(@"❌ Model is null");
        return nil;
    }
    
    NSLog(@"🔥 Generating response with temp:%.2f, topP:%.2f, maxTokens:%d", temperature, topP, maxTokens);
    
    // Recreate context for fresh state (no KV cache conflicts)
    if (ctx) {
        llama_free(ctx);
        ctx = nil;
    }
    
    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = contextSize;  // Use stored context size
    ctx_params.n_batch = 512;
    ctx_params.n_threads = 4;
    
    ctx = llama_init_from_model(model, ctx_params);
    if (!ctx) {
        NSLog(@"❌ Failed to recreate context");
        return nil;
    }
    NSLog(@"✅ Context recreated with fresh KV cache");
    
    // Get vocab for tokenization
    const struct llama_vocab * vocab = llama_model_get_vocab(model);
    
    // Tokenize prompt
    std::vector<llama_token> tokens_list;
    const char *prompt_c = [prompt UTF8String];
    
    tokens_list.resize(512);
    int n_tokens = llama_tokenize(
        vocab,  // Changed from 'model' to 'vocab'
        prompt_c,
        strlen(prompt_c),
        tokens_list.data(),
        tokens_list.size(),
        true, // add_bos
        false // special
    );
    
    if (n_tokens < 0) {
        tokens_list.resize(-n_tokens);
        n_tokens = llama_tokenize(
            vocab,  // Changed from 'model' to 'vocab'
            prompt_c,
            strlen(prompt_c),
            tokens_list.data(),
            tokens_list.size(),
            true,
            false
        );
    }
    
    tokens_list.resize(n_tokens);
    NSLog(@"📝 Tokenized input: %d tokens", n_tokens);
    
    // Create batch
    llama_batch batch = llama_batch_init(512, 0, 1);
    
    // Add tokens to batch manually
    for (size_t i = 0; i < tokens_list.size(); i++) {
        batch.token[i] = tokens_list[i];
        batch.pos[i] = i;
        batch.n_seq_id[i] = 1;
        batch.seq_id[i][0] = 0;
        batch.logits[i] = false;
    }
    batch.n_tokens = tokens_list.size();
    
    // Mark last token as needing logits
    if (batch.n_tokens > 0) {
        batch.logits[batch.n_tokens - 1] = true;
    }
    
    // Decode
    if (llama_decode(ctx, batch) != 0) {
        NSLog(@"❌ llama_decode failed");
        llama_batch_free(batch);
        return nil;
    }
    
    NSLog(@"✅ Initial decode successful");
    
    // Create sampler with provided parameters
    auto sparams = llama_sampler_chain_default_params();
    llama_sampler * local_sampler = llama_sampler_chain_init(sparams);
    llama_sampler_chain_add(local_sampler, llama_sampler_init_temp(temperature));
    llama_sampler_chain_add(local_sampler, llama_sampler_init_top_p(topP, 1));
    llama_sampler_chain_add(local_sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));
    
    // Generate tokens
    NSMutableString *result = [NSMutableString string];
    int n_generated = 0;
    const int max_tokens = maxTokens;
    
    while (n_generated < max_tokens) {
        llama_token new_token = llama_sampler_sample(local_sampler, ctx, -1);
        
        // Check for end of generation token
        if (llama_vocab_is_eog(vocab, new_token)) {
            NSLog(@"🏁 EOS token reached");
            break;
        }
        
        // Convert token to text
        char buf[256];
        int n = llama_token_to_piece(vocab, new_token, buf, sizeof(buf), 0, false);
        if (n > 0) {
            NSString *piece = [[NSString alloc] initWithBytes:buf length:n encoding:NSUTF8StringEncoding];
            if (piece) {
                [result appendString:piece];
            }
        }
        
        // Prepare batch for next token
        batch.n_tokens = 1;
        batch.token[0] = new_token;
        batch.pos[0] = tokens_list.size() + n_generated;
        batch.n_seq_id[0] = 1;
        batch.seq_id[0][0] = 0;
        batch.logits[0] = true;
        
        // Decode
        if (llama_decode(ctx, batch) != 0) {
            NSLog(@"❌ Decode failed at token %d", n_generated);
            break;
        }
        
        n_generated++;
    }
    
    llama_batch_free(batch);
    llama_sampler_free(local_sampler);
    
    NSLog(@"✅ Generated %d tokens", n_generated);
    NSLog(@"📤 Response: %@", result);
    
    return [result copy];
}

- (void)cleanup {
    // Sampler is now created per generation, no need to clean up here
    if (ctx) {
        llama_free(ctx);
        ctx = nil;
    }
    if (model) {
        llama_model_free(model);
        model = nil;
    }
    // Don't free llama_backend since it's now a global singleton
    // llama_backend_free();
}

- (void)dealloc {
    [self cleanup];
}

@end
