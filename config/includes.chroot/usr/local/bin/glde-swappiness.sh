#!/usr/bin/env bash
# GLDE adaptive swappiness tuning (правка из visual-gl).
# Запускается systemd-сервисом glde-swappiness.service при каждой загрузке.

set -u

total_memory=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
swappiness_value=0

if ((total_memory <= 4)); then
    swappiness_value=10
elif ((total_memory <= 8)); then
    swappiness_value=20
elif ((total_memory <= 16)); then
    swappiness_value=30
else
    swappiness_value=$(cat /proc/sys/vm/swappiness)
fi

echo "Текущее значение параметра swappiness: $(cat /proc/sys/vm/swappiness)"
echo "Общий объем оперативной памяти: ${total_memory} ГБ"

if ((swappiness_value > 0)); then
    echo "Устанавливаем параметр swappiness в ${swappiness_value}"
    sysctl -q vm.swappiness="${swappiness_value}"
    echo "Параметр swappiness успешно изменён"
else
    echo "Параметр swappiness не требует изменений"
fi

exit 0
