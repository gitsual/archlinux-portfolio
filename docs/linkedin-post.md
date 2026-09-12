He convertido mi workstation real de Arch Linux en un portfolio público y reproducible:

https://github.com/gitsual/archlinux-portfolio

No es una copia de mi carpeta personal. He tratado toda la configuración como un sistema que otra persona pueda estudiar y reconstruir sin publicar datos privados.

Incluye:

- escritorio Wayland completo con Hyprland, Waybar, Kitty y Dunst;
- Rofi, dmenu y Wofi como launchers;
- la configuración activa de Neovim/NvChad, su skin, plugins bloqueados y Avante como única interfaz de IA;
- perfiles reproducibles de PipeWire, WirePlumber y Bluetooth para equilibrar calidad, latencia y estabilidad;
- una arquitectura recomendada de almacenamiento: Btrfs para sistema y HOME, datos Linux separados y una capa compartida opcional;
- UFW, ClamAV, rkhunter y Lynis como defensa y auditoría por capas;
- instalación con Pacman y GNU Stow, copias de seguridad automáticas ante conflictos y perfiles opcionales por hardware;
- pruebas de idempotencia en un HOME temporal;
- escaneo de secretos, rutas personales, identificadores de dispositivos, redes privadas y del historial Git antes de publicar.

La parte más interesante no ha sido guardar dotfiles, sino convertir decisiones muy ligadas a una máquina concreta en una arquitectura pública, documentada y segura. Los UUID, nombres de discos, nodos de audio, credenciales y rutas locales se generan o configuran en cada equipo y nunca forman parte del repositorio.

#ArchLinux #Linux #Hyprland #Wayland #Neovim #Dotfiles #DevOps #OpenSource #CyberSecurity
