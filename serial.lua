function get_serial_number()
    local info = os_capture("cat /proc/cpuinfo")
    local _, _, serial = string.find(info, "Serial%s+:%s+(%w+)")
    return serial
end
