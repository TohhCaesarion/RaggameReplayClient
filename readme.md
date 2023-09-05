## Raggame Replay Client

В данном репозитории вы найдете клиент РО, собранный на основе клиента Raggame.ru Organic закрывшегося в 2015 году.  

Главная цель этой сборки клиента - это возможность воспроизведения старых реплеев в формате .rrf, созданных в период с 2011 по 2013 год.

### Архив записей

Эта сборка также включает в себя архив из более чем 2000 файлов записей. Эти записи были созданы гильдиями Caesarion, Rebellion и Indulgencia в период с 2011 по 2013 год.

### Как запустить

1. Склонируйте репозиторий с Github.
   
2. Установите vcredist через **vcredist/install_all.bat**.

3. Запустите файл **client/opensetup.exe**, чтобы настроить разрешение экрана. Если разрешение вашего монитора отсутствует в списке, отключите полноэкранный режим. В принципе вы можете установить любое разрешение экрана, отредактировав файл **client/System/optioninfo.lua** в блокноте.

4. Для скрытия списка активных квестов, используйте файл **client/Отключить квесты.exe**. В правом верхнем углу экрана начиная с ~13 эпизода висит список активных квестов. Его нельзя никак скрыть изнутри игры, и в opensetup.exe тоже такой опции нет, поэтому я сделал отдельную программку.

5. После завершения настроек открывайте папку **client/Replay**. В этой папке находятся сами файлы реплеев в формате .rrf и они сгруппированы по никнеймам и раскиданы по подпапкам с соответствующими названиями вроде **client/Replay/Waladar** или **client/Replay/Denchik**. Выбирайте те реплеи, которые вам интересны и копируйте .rrf-файлы в родительскую папку - запускать можно только те файлы, которые лежат непосредственно в **client/Replay**.

6. В завершении, убедитесь, что файл **client/2012-07-02aRagexe_patched.exe** добавлен в исключения Windows Defender или другой антивирусной программы, если он распознается как недоверенный.

7. Запустите **client/2012-07-02aRagexe_patched.exe** и нажмите кнопку Replay, чтобы перейти к списку записей.

### Особенности

- **Улучшения камеры:** Мы применили патчи для увеличения угла обзора и дистанции камеры: Камера отдаляется дальше колесиком мыши. Камера поворачивается на больший угол если двигаете через shift+правый клик.
- **Эмблемы гильдий:** У плеера реплеев РО есть известная проблема с эмблемами. Эмблемы в файле реплея не сохраняются. Эмблемы загружаются из папки, куда они сохраняются когда в игре вы встречаете игрока из соответствующей гильдии. Если с момента записи реплея у гильдии поменялась эмблема, а клиент переустанавливали, то даже если вы найдете в игре представителя гильдии с новой эмблемой - в старом реплее не будет показываться ни старая ни новая, если у вас нет старого файла эмблемы. Для таких случаев я заменил старые эмблемы копиями тех какие были. Также на некоторых реплеях были гильдии для которых не нашлось вообще никакой эмблемы - например гильдия Indulgencia, за которую записано много ГВ ТЕ. Для таких случаев я заменял эмблему каким-нибудь спрайтом из РО, чтобы при просмотре записи хоть как-то можно было отличить чужих от своих.

### Известные баги

- На некоторых реплеях клиент вылетает при запуске или нажатии кнопки стоп или при выходе в список выбора реплея. Решения нет - надо просто заново зайти в игру.

**Приятной игры!**

<hr>

## Raggame Replay Client

This is a repository of a RO game client for Raggame.ru Organic server aka RuRO that has become inactive in 2015.

The main purpose of this client build is to enable the playback of old .rrf replays that were created between 2011 and 2013.

### Recordings Archive

This build also includes an archive of over 2000 replay files. These recordings were created by the guilds Caesarion, Rebellion, and Indulgencia between 2011 and 2013.

### How to Run

1. Сlone the repository from GitHub.

2. Install vcredist through `vcredist/install_all.bat`.

3. Run the file `client/opensetup.exe` to configure the screen resolution. If your monitor's resolution is not in the list, disable fullscreen mode. You can set any screen resolution by editing the file `client/System/optioninfo.lua` in Notepad.

4. To hide the list of active quests, use the file `client/Отключить квесты.exe`. Starting from episode ~13, there is a list of active quests in the upper right corner of the screen. You cannot hide it from within the game, and opensetup.exe does not have such an option, so I made a separate program for it.

5. After configuring, open the folder `client/Replay`. In this folder, you will find the actual .rrf replay files, grouped by nicknames and placed in subfolders with corresponding names such as `client/Replay/Waladar` or `client/Replay/Denchik`. Select the replays you are interested in and copy the .rrf files to the parent folder - you can only run files that are located directly in `client/Replay`.

6. Finally, make sure that the file `client/2012-07-02aRagexe_patched.exe` is added to Windows Defender or another antivirus program's exceptions if it is detected as untrusted.

7. Run `client/2012-07-02aRagexe_patched.exe` and click the Replay button to access the list of recordings.

### Features

- **Camera Enhancements:** We applied patches to increase the field of view and camera distance: The camera zooms out further with the mouse wheel. The camera rotates at a greater angle when moving through shift+right-click.
- **Guild Emblems:** RO player recordings have a known issue with guild emblems. Emblems are not saved in the replay file. Emblems are loaded from the folder where they are saved when you encounter a player from the corresponding guild in the game. If the guild has changed its emblem since the recording was made, and you have reinstalled the client, even if you find a player in the game with the new emblem, the old or new emblem will not be displayed in the old replay unless you have the old emblem file. For such cases, I replaced the old emblems with copies of what they were. Also, on some replays, there were guilds for which no emblem could be found at all - for example, the Indulgencia guild, for which many GvE recordings were made. In such cases, I replaced the emblem with some sprite from RO, so that you could somehow distinguish between friend and foe during replay.

### Known Bugs

- On some replays, the client crashes when launched or when pressing the stop button or when exiting to the replay selection list. There is no solution - you simply need to re-enter the game.

**Enjoy your game!**
