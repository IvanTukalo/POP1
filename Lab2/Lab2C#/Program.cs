using System;
using System.Diagnostics;
using System.Threading;

namespace Lab2Csharp
{
    class Program
    {
        private readonly int dim = 2000000000;
        private int[] arr;

        private int completedThreads;
        private readonly object locker = new object();

        static void Main(string[] args)
        {
            Console.OutputEncoding = System.Text.Encoding.UTF8;
            Program program = new Program();
            program.Run();
        }

        public void Run()
        {
            Console.WriteLine("Генерація масиву...");
            arr = new int[dim];
            Random rnd = new Random();

            for (int i = 0; i < dim; i++)
            {
                arr[i] = rnd.Next(1, 101);
            }

            int randomIndex = rnd.Next(0, dim);
            int minV = -1;
            arr[randomIndex] = minV;
            Console.WriteLine("Масив згенеровано.");

            Stopwatch sw = new Stopwatch();
            sw.Start();

            var seqResult = FindMinInRange(0, dim);

            sw.Stop();
            long sequentialTimeMs = sw.ElapsedMilliseconds;
            Console.WriteLine($"Послідовний пошук: знайдено значення {seqResult.min} (індекс {seqResult.index}), за {sequentialTimeMs} мс");

            long fastestTimeMs = long.MaxValue;
            int fastestThreadCount = 0;

            for (int treadNumber = 2; treadNumber <= 20; treadNumber += 2)
            {
                completedThreads = 0;
                var results = new (int min, int index)[treadNumber];
                int chunkSize = dim / treadNumber;

                sw.Restart();

                for (int i = 0; i < treadNumber; i++)
                {
                    int start = i * chunkSize;
                    int end = (i == treadNumber - 1) ? dim : start + chunkSize;
                    int localThreadIndex = i;

                    Thread thread = new Thread(() =>
                    {
                        // 1. Абсолютно чисте обчислення без блокувань
                        results[localThreadIndex] = FindMinInRange(start, end);

                        // 2. Сигналізація про завершення роботи потоку
                        lock (locker)
                        {
                            completedThreads++;
                            Monitor.Pulse(locker);
                        }
                    });

                    thread.Start();
                }

                // Головний потік чекає на сигнали від усіх дочірніх потоків
                lock (locker)
                {
                    while (completedThreads < treadNumber)
                    {
                        Monitor.Wait(locker);
                    }
                }

                // Агрегація результатів після того, як всі відзвітували
                int globalMin = int.MaxValue;
                int globalMinIndex = -1;

                for (int i = 0; i < treadNumber; i++)
                {
                    if (results[i].min < globalMin)
                    {
                        globalMin = results[i].min;
                        globalMinIndex = results[i].index;
                    }
                }

                sw.Stop();
                long currentElapsed = sw.ElapsedMilliseconds;

                if (currentElapsed < fastestTimeMs)
                {
                    fastestTimeMs = currentElapsed;
                    fastestThreadCount = treadNumber;
                }

                Console.WriteLine($"{treadNumber} потоки(ів) знайшли мінімальний елемент: значення {globalMin} (індекс {globalMinIndex}), за {currentElapsed} мс");
            }

            double speedup = (double)sequentialTimeMs / fastestTimeMs;
            Console.WriteLine($"\nПошук з {fastestThreadCount} потоками найшвидший – {fastestTimeMs} мс в {speedup:F2}x швидше");

            Console.ReadKey();
        }

        // Чистий метод пошуку (тільки обчислення)
        private (int min, int index) FindMinInRange(int startIndex, int endIndex)
        {
            int localMin = int.MaxValue;
            int localMinIndex = -1;

            for (int i = startIndex; i < endIndex; i++)
            {
                if (arr[i] < localMin)
                {
                    localMin = arr[i];
                    localMinIndex = i;
                }
            }

            return (localMin, localMinIndex);
        }
    }
}