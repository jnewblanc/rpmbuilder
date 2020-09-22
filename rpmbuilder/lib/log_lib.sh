# log_lib.sh - Logging functions

log() {
  local msg=$1
  local date=`date "+%Y-%m-%d %H:%M"`
  echo "${date} $msg"
}
