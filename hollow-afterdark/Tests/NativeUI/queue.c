#include <AudioToolbox/AudioToolbox.h>
#include <CoreAudio/CoreAudio.h>
#include <mach/mach_time.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

static FILE *pcm, *logfile;
static uint64_t frames = 0;
static mach_timebase_info_data_t tb;
static volatile sig_atomic_t stopping = 0;
static double seconds(uint64_t t) { return t * (double)tb.numer / tb.denom / 1e9; }
static void stop(int s) { (void)s; stopping = 1; }
static void check(OSStatus s, const char *name) {
  if (s) { fprintf(stderr, "%s status=%d\n", name, (int)s); exit(1); }
}
static void input(void *context, AudioQueueRef q, AudioQueueBufferRef b,
                  const AudioTimeStamp *t, UInt32 packets,
                  const AudioStreamPacketDescription *descriptions) {
  (void)context;
  (void)packets;
  (void)descriptions;
  UInt32 n = b->mAudioDataByteSize / 4;
  size_t written = fwrite(b->mAudioData, 1, b->mAudioDataByteSize, pcm);
  fprintf(logfile, "{\"frame_offset\":%llu,\"frames\":%u,\"bytes\":%u,"
    "\"written\":%zu,\"sample_time\":%.9f,\"host_seconds\":%.9f,"
    "\"callback_host_seconds\":%.9f,\"flags\":%u}\n",
    frames, n, b->mAudioDataByteSize, written, t->mSampleTime,
    seconds(t->mHostTime), seconds(mach_absolute_time()), t->mFlags);
  fflush(logfile);
  frames += n;
  if (!stopping) check(AudioQueueEnqueueBuffer(q,b,0,NULL),"enqueue");
}
int main(int argc, char **argv) {
  if (argc != 3) return 2;
  mach_timebase_info(&tb);
  char path[4096];
  snprintf(path,sizeof(path),"%s.s16le",argv[1]); pcm=fopen(path,"wb");
  snprintf(path,sizeof(path),"%s.jsonl",argv[1]); logfile=fopen(path,"w");
  if (!pcm || !logfile) return 3;
  AudioDeviceID device;
  UInt32 size=sizeof(device);
  AudioObjectPropertyAddress a={kAudioHardwarePropertyDefaultInputDevice,
    kAudioObjectPropertyScopeGlobal,kAudioObjectPropertyElementMain};
  check(AudioObjectGetPropertyData(kAudioObjectSystemObject,&a,0,NULL,&size,&device),
    "default input");
  CFStringRef uid;
  a.mSelector=kAudioDevicePropertyDeviceUID; size=sizeof(uid);
  check(AudioObjectGetPropertyData(device,&a,0,NULL,&size,&uid),"input uid");
  char uidText[256]; CFStringGetCString(uid,uidText,sizeof(uidText),kCFStringEncodingUTF8);
  fprintf(stderr,"input_device=%u uid=%s sample_rate=48000 channels=2\n",device,uidText);
  AudioStreamBasicDescription f={0};
  f.mSampleRate=48000; f.mFormatID=kAudioFormatLinearPCM;
  f.mFormatFlags=kLinearPCMFormatFlagIsSignedInteger|kLinearPCMFormatFlagIsPacked;
  f.mBytesPerPacket=4; f.mFramesPerPacket=1; f.mBytesPerFrame=4;
  f.mChannelsPerFrame=2; f.mBitsPerChannel=16;
  AudioQueueRef q;
  check(AudioQueueNewInput(&f,input,NULL,CFRunLoopGetCurrent(),
    kCFRunLoopCommonModes,0,&q),"new input");
  check(AudioQueueSetProperty(q,kAudioQueueProperty_CurrentDevice,&uid,sizeof(uid)),
    "bind BlackHole input");
  CFRelease(uid);
  for(int i=0;i<4;i++) {
    AudioQueueBufferRef b;
    check(AudioQueueAllocateBuffer(q,8192,&b),"allocate");
    check(AudioQueueEnqueueBuffer(q,b,0,NULL),"enqueue initial");
  }
  signal(SIGINT,stop); signal(SIGTERM,stop);
  struct timeval wall; gettimeofday(&wall,NULL);
  fprintf(stderr,"start_requested_host=%.9f unix=%.6f\n",
    seconds(mach_absolute_time()),wall.tv_sec+wall.tv_usec/1e6);
  check(AudioQueueStart(q,NULL),"start");
  double end=seconds(mach_absolute_time())+atof(argv[2]);
  while(!stopping && seconds(mach_absolute_time())<end)
    CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.05,false);
  stopping=1;
  check(AudioQueueStop(q,true),"stop");
  check(AudioQueueDispose(q,true),"dispose");
  fclose(pcm); fclose(logfile);
  fprintf(stderr,"finished_host=%.9f frames=%llu audio_seconds=%.9f\n",
    seconds(mach_absolute_time()),frames,frames/48000.0);
  return 0;
}
