import pathlib,json,subprocess
root=pathlib.Path(__file__).resolve().parent
script=json.loads((root/'review-script.json').read_text())
times=[2.0]
pos=3.5
for c in script['chapters']:
 times.append(pos+1.2)
 pos+=2.5
 duration=c['to']-c['from']
 times.append(pos+duration/2)
 pos+=duration
times.append(pos+3)
for i,t in enumerate(times):
 subprocess.run(['ffmpeg','-y','-loglevel','error','-ss',str(t),'-i',str(root/'review-video.mp4'),'-frames:v','1',str(root/f'review-validation-{i:02}.png')],check=True)
subprocess.run(['ffmpeg','-y','-loglevel','error','-framerate','1','-i',str(root/'review-validation-%02d.png'),'-vf','scale=384:216,tile=4x6','-frames:v','1',str(root/'review-validation-contact-sheet.png')],check=True)
subprocess.run(['ffmpeg','-v','error','-i',str(root/'review-video.mp4'),'-f','null','-'],check=True)
(root/'review-validation.json').write_text(json.dumps({'sample_seconds':times,'all_frames_decoded':True,'expected_duration':pos+6},indent=2))
