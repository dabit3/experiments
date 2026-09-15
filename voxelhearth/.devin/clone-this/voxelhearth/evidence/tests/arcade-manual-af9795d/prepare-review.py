import pathlib,subprocess,json
root=pathlib.Path(__file__).resolve().parent
rec=pathlib.Path('/Users/devin/screencasts/vh-arcade-af9795d')
raws=sorted(rec.glob('*-raw-*.mkv'))
(root/'raw-concat.txt').write_text(''.join(f"file '{p}'\n" for p in raws))
subprocess.run(['ffmpeg','-y','-loglevel','error','-f','concat','-safe','0','-i',str(root/'raw-concat.txt'),'-c','copy',str(root/'raw-footage.mkv')],check=True)
src=rec/'vh-arcade-af9795d-clean.mp4'
times=[5,13,31,37,46,53,72,78,82,86,90,108,119,123,137,144,155,159,162,165,169,171]
for i,t in enumerate(times):
 p=root/f'review-sample-{i:02}.png'
 subprocess.run(['ffmpeg','-y','-loglevel','error','-ss',str(t),'-i',str(src),'-frames:v','1',str(p)],check=True)
subprocess.run(['ffmpeg','-y','-loglevel','error','-framerate','1','-i',str(root/'review-sample-%02d.png'),'-vf','scale=320:240,tile=4x6','-frames:v','1',str(root/'review-contact-sheet.png')],check=True)
