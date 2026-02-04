local subliminal = '/usr/bin/subliminal'

local languages = {
    { 'English', 'en', 'eng' },
    { 'Bangla', 'bn', 'ben' },
}

local logins = {
--  { '--opensubtitles', 'USER', 'PASS' },
}

--=============================================================================
-->>    ADDITIONAL OPTIONS:
--=============================================================================
local bools = {
    auto = true,   -- Automatically download subtitles
    debug = false, -- Use `--debug` in terminal
    force = true,  -- Overwrite existing subtitle files
    utf8 = true,   -- Save as UTF-8
}
local excludes = { 'no-subs-dl' }
local includes = { }

--=============================================================================
local utils = require 'mp.utils'

-- Download function: modified to create and use /subtitles folder
function download_subs(language)
    language = language or languages[1]
    if #language == 0 then
        log('No Language found\n')
        return false
    end
            
    log('Searching ' .. language[1] .. ' subtitles ...', 30)

    -- 1. Create the subtitles folder automatically
    local sub_dir = utils.join_path(directory, "subtitles")
    os.execute('mkdir -p "' .. sub_dir .. '"')

    -- 2. Build the subliminal command
    local table = { args = { subliminal } }
    local a = table.args

    for _, login in ipairs(logins) do
        a[#a + 1] = login[1]
        a[#a + 1] = login[2]
        a[#a + 1] = login[3]
    end
    if bools.debug then
        a[#a + 1] = '--debug'
    end

    a[#a + 1] = 'download'
    if bools.force then
        a[#a + 1] = '-f'
    end
    if bools.utf8 then
        a[#a + 1] = '-e'
        a[#a + 1] = 'utf-8'
    end

    a[#a + 1] = '-l'
    a[#a + 1] = language[2]
    
    -- 3. Set destination to the new subfolder
    a[#a + 1] = '-d'
    a[#a + 1] = sub_dir
    
    -- 4. Provide the full path to the video file
    a[#a + 1] = utils.join_path(directory, filename)

    local result = utils.subprocess(table)

    if string.find(result.stdout or "", 'Downloaded 1 subtitle') then
        mp.set_property('slang', language[2])
        mp.commandv('rescan_external_files')
        log(language[1] .. ' subtitles ready!')
        return true
    else
        log('No ' .. language[1] .. ' subtitles found\n')
        return false
    end
end

function download_subs2()
    download_subs(languages[2])
end

function control_downloads()
    mp.set_property('sub-auto', 'fuzzy')
    mp.set_property('slang', languages[1][2])
    mp.commandv('rescan_external_files')
    directory, filename = utils.split_path(mp.get_property('path'))

    if not autosub_allowed() then return end

    sub_tracks = {}
    for _, track in ipairs(mp.get_property_native('track-list')) do
        if track['type'] == 'sub' then
            sub_tracks[#sub_tracks + 1] = track
        end
    end

    for _, language in ipairs(languages) do
        if should_download_subs_in(language) then
            if download_subs(language) then return end
        else return end
    end
end

function autosub_allowed()
    local duration = tonumber(mp.get_property('duration'))
    local active_format = mp.get_property('file-format')

    if not bools.auto then return false
    elseif duration and duration < 900 then return false
    elseif directory:find('^http') then return false
    else
        for _, exclude in pairs(excludes) do
            if directory:find(exclude:gsub('%W','%%%0')) then return false end
        end
    end
    return true
end

function should_download_subs_in(language)
    for i, track in ipairs(sub_tracks) do
        if track['lang'] == language[3] or track['lang'] == language[2] or
          (track['title'] and track['title']:lower():find(language[3])) then
            if not track['selected'] then mp.set_property('sid', track['id']) end
            return false
        end
    end
    return true
end

function log(string, secs)
    secs = secs or 2.5
    mp.msg.warn(string)
    mp.osd_message(string, secs)
end

mp.add_key_binding('b', 'download_subs', download_subs)
mp.add_key_binding('n', 'download_subs2', download_subs2)
mp.register_event('file-loaded', control_downloads)
