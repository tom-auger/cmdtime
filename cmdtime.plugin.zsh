zmodload zsh/datetime

__cmdtime_current_time() {
  echo $EPOCHREALTIME
}

__cmdtime_format_duration() {
  local hours=$(printf '%.0f' $(($1 / 3600)))
  local mins=$(printf '%.0f' $((($1 - hours * 3600) / 60)))
  local secs=$(printf "%.3f" $(($1 - 60 * mins - 3600 * hours)))

  if [[ ! "${mins}" == "0" ]] || [[ ! "${hours}" == "0" ]]; then
      # If there are a non zero number of minutes or hours 
      # then display integer number of seconds
      secs=${secs%\.*}
  elif [[ "${secs}" =~ "^0\..*" ]]; then
      # If secs starts with 0. i.e. is less than 1 then display
      # the number of milliseconds instead. Strip off the leading 
      # zeros and append an 'm'. 
      secs="${${${secs#0.}#0}#0}m"
  else
      # Display seconds to 2dp
      secs=${secs%?}
  fi
  local duration_str=$(echo "${hours}h:${mins}m:${secs}s")
  local format="${TIMER_FORMAT:-%d}"
  echo "${format//\%d/${${duration_str#0h:}#0m:}}"
}

__cmdtime_save_time_preexec() {
  __cmdtime_cmd_start_time=$(__cmdtime_current_time)
}

__cmdtime_display_cmdtime_precmd() {
  if [ -n "${__cmdtime_cmd_start_time}" ]; then
    local cmd_end_time=$(__cmdtime_current_time)
    local tdiff=$((cmd_end_time - __cmdtime_cmd_start_time))
    unset __cmdtime_cmd_start_time
    if [[ -z "${TIMER_THRESHOLD}" || ${tdiff} -ge "${TIMER_THRESHOLD}" ]]; then
        local tdiffstr=$(__cmdtime_format_duration ${tdiff})
        local cols=$((COLUMNS - ${#tdiffstr} - 1))
        echo -e "\033[1A\033[${cols}C \e[2m${tdiffstr}"
    fi
  fi
}

autoload -U add-zsh-hook
add-zsh-hook preexec __cmdtime_save_time_preexec
add-zsh-hook precmd __cmdtime_display_cmdtime_precmd
