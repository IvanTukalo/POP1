using System;
using System.Threading;
using System.Numerics;

namespace Lab1Csharp
{
    class Program
    {
        static void Main(string[] args)
        {
            Thread.CurrentThread.CurrentCulture = new System.Globalization.CultureInfo("en-US");
            Console.OutputEncoding = System.Text.Encoding.UTF8;
            Console.ForegroundColor = ConsoleColor.Black;
            Console.BackgroundColor = ConsoleColor.White;
            Console.Clear();

            while (true)
            {
                int step;
                while (true)
                {
                    Console.WriteLine("Введіть крок роботи потоків");
                    if (int.TryParse(Console.ReadLine(), out step) && step > 0)
                    {
                        break;
                    }
                    Console.WriteLine("Помилка вводу. Будь ласка, введіть ціле додатне число.");
                }

                int[] times;
                while (true)
                {
                    Console.WriteLine("Введіть час роботи потоків у секундах через пробіл");
                    string input = Console.ReadLine();

                    if (string.IsNullOrWhiteSpace(input))
                    {
                        continue;
                    }

                    string[] timesStr = input.Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
                    times = new int[timesStr.Length];
                    bool allValid = true;

                    for (int i = 0; i < timesStr.Length; i++)
                    {
                        if (!int.TryParse(timesStr[i], out times[i]) || times[i] <= 0)
                        {
                            allValid = false;
                            break;
                        }
                    }

                    if (allValid)
                    {
                        break;
                    }
                    Console.WriteLine("Помилка вводу. Переконайтеся, що ви ввели лише цілі додатні числа через пробіл.");
                }

                int numThreads = times.Length;
                int maxTime = 0;
                for (int i = 0; i < numThreads; i++)
                {
                    if (times[i] > maxTime) maxTime = times[i];
                }

                int[] stopFlags = new int[numThreads];
                Thread[] threads = new Thread[numThreads];

                for (int i = 0; i < numThreads; i++)
                {
                    int localIndex = i;
                    int timeLimit = times[i];
                    int threadId = i + 1;

                    threads[i] = new Thread(() => {
                        BigInteger sum = 0;
                        BigInteger elementsCount = 0;

                        while (Volatile.Read(ref stopFlags[localIndex]) == 0)
                        {
                            sum += step;
                            elementsCount++;
                        }

                        Console.WriteLine($"{threadId} - {sum}, {step} - {elementsCount} разів за {timeLimit} сек.");
                    });
                    threads[i].Start();
                }

                Thread masterStopper = new Thread(() => {
                    var events = new (int Time, int Index)[numThreads];
                    for (int i = 0; i < numThreads; i++)
                    {
                        events[i] = (times[i], i);
                    }
                    Array.Sort(events, (a, b) => a.Time.CompareTo(b.Time));

                    int elapsed = 0;
                    for (int i = 0; i < numThreads; i++)
                    {
                        int sleepTime = events[i].Time - elapsed;
                        if (sleepTime > 0)
                        {
                            Thread.Sleep(sleepTime * 1000);
                            elapsed += sleepTime;
                        }
                        Volatile.Write(ref stopFlags[events[i].Index], 1);
                    }
                });
                masterStopper.Start();

                Thread.Sleep((maxTime + 1) * 1000);

                Console.WriteLine("\nУсі потоки завершили роботу. Починаємо новий цикл.");
                Console.WriteLine();
            }
        }
    }
}