using System;
using WindowsDesktop; // Usamos el nuevo namespace

public class VDesktopHelper
{
    // El atributo [STAThread] es crucial para evitar errores con las APIs del Shell.
    [STAThread]
    public static void Main(string[] args)
    {
        if (args.Length == 0) return;

        string command = args[0].ToLower();

        try
        {
            switch (command)
            {
                case "get_count":
                    // La nueva API devuelve un array, obtenemos su longitud.
                    Console.Write(VirtualDesktop.GetDesktops().Length);
                    break;

                case "move_adj": // "Move Adjacent"
                    if (args.Length == 3)
                    {
                        IntPtr windowHandle = new IntPtr(long.Parse(args[1]));
                        int direction = int.Parse(args[2]); // 1 para derecha/siguiente, -1 para izquierda/anterior

                        // Obtenemos el escritorio actual de la ventana. ¡Mucho más preciso!
                        var currentDesktop = VirtualDesktop.FromHwnd(windowHandle);
                        if (currentDesktop == null) return; // La ventana está fija o no se encontró

                        VirtualDesktop? targetDesktop = null;

                        if (direction > 0) // Mover a la derecha (siguiente)
                        {
                            targetDesktop = currentDesktop.GetRight();
                            if (targetDesktop == null) // Si no hay más a la derecha, envolvemos al primero.
                            {
                                targetDesktop = VirtualDesktop.GetDesktops()[0];
                            }
                        }
                        else // Mover a la izquierda (anterior)
                        {
                            targetDesktop = currentDesktop.GetLeft();
                            if (targetDesktop == null) // Si no hay más a la izquierda, envolvemos al último.
                            {
                                var desktops = VirtualDesktop.GetDesktops();
                                targetDesktop = desktops[desktops.Length - 1];
                            }
                        }

                        // Movemos la ventana al escritorio de destino.
                        VirtualDesktop.MoveToDesktop(windowHandle, targetDesktop);
                    }
                    break;
            }
        }
        catch (Exception)
        {
            // Fallar silenciosamente para no interrumpir el script de AHK.
        }
    }
}
