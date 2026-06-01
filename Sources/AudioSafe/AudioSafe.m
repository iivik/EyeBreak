#import "AudioSafe.h"

BOOL EBSafePlay(AVAudioPlayerNode *node) {
    @try {
        [node play];
        return YES;
    } @catch (NSException *exception) {
        return NO;
    }
}
