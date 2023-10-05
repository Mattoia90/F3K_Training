@echo off

rem Path to Balabolka command line tool
set AUDIO_GEN_TOOL=d:\tools\Balabolka\cmd\balcon.exe 
set AUDIO_OUTPUT_DIR=F3K_TRAINING\sndhd
set OPTIONS=-n "Microsoft Zira Desktop"

%AUDIO_GEN_TOOL% %OPTIONS% -t "invalid flight" -w %AUDIO_OUTPUT_DIR%/badflight.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "sorry, but you can't improve anymore" -w %AUDIO_OUTPUT_DIR%/cant.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "next target" -w %AUDIO_OUTPUT_DIR%/nxttarget.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "time remaining" -w %AUDIO_OUTPUT_DIR%/remaining.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "stop, don't throw" -w %AUDIO_OUTPUT_DIR%/stop.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task A, last flight, max 5 minutes" -w %AUDIO_OUTPUT_DIR%/taska.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task B, last 2 flights, max 4 minutes" -w %AUDIO_OUTPUT_DIR%/taskb.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task B, last 2 flights, max 3 minutes" -w %AUDIO_OUTPUT_DIR%/taskb7.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task C, all up last down, max 3 minutes" -w %AUDIO_OUTPUT_DIR%/taskc.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task D, 2 flights only, 5 minutes target each flight, 10 minute working window" -w %AUDIO_OUTPUT_DIR%/taskd.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task D, ladder" -w %AUDIO_OUTPUT_DIR%/taskd2.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "end of task" -w %AUDIO_OUTPUT_DIR%/taskend.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task F, 3 out of 6, max 3 minutes" -w %AUDIO_OUTPUT_DIR%/taskf.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "free flight, have fun" -w %AUDIO_OUTPUT_DIR%/taskff.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task G, 5 longest flights, max 2 minutes" -w %AUDIO_OUTPUT_DIR%/taskg.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task H, 1, 2, 3 and 4 minutes, in any order" -w %AUDIO_OUTPUT_DIR%/taskh.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task I, 3 longest flights, 3:20 max" -w %AUDIO_OUTPUT_DIR%/taski.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task J, 3 last flights, max 3 minutes" -w %AUDIO_OUTPUT_DIR%/taskj.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task K, big ladder" -w %AUDIO_OUTPUT_DIR%/taskk.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task L, one flight only, 9:59 max" -w %AUDIO_OUTPUT_DIR%/taskl.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "task M, huge ladder, target flights in order, 3, 5 and 7 minutes, 15 minutes working window" -w %AUDIO_OUTPUT_DIR%/taskm.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "quick turnaround practice, 40 seconds flights" -w %AUDIO_OUTPUT_DIR%/taskqt.wav
%AUDIO_GEN_TOOL% %OPTIONS% -t "well done" -w %AUDIO_OUTPUT_DIR%/welldone.wav

