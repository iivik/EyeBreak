#ifndef AudioSafe_h
#define AudioSafe_h

#import <AVFoundation/AVFoundation.h>

/// Calls -[AVAudioPlayerNode play] inside @try/@catch so that the
/// NSException thrown by AVAudio when the hardware is not ready (e.g.
/// immediately after wake from sleep) is swallowed rather than aborting.
/// Returns YES if play succeeded, NO if an exception was caught.
BOOL EBSafePlay(AVAudioPlayerNode *node);

#endif /* AudioSafe_h */
