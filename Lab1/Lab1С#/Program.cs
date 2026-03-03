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

                Worker[] workers = new Worker[numThreads];
                Thread[] workerThreads = new Thread[numThreads];
                Thread[] stopperThreads = new Thread[numThreads];

                for (int i = 0; i < numThreads; i++)
                {
                    int timeLimit = times[i];
                    int threadId = i + 1;

                    workers[i] = new Worker(threadId, step, timeLimit);
                    workerThreads[i] = new Thread(workers[i].Calculate);

                    int currentIndex = i;
                    stopperThreads[i] = new Thread(() => {
                        Thread.Sleep(timeLimit * 1000);
                        workers[currentIndex].Stop();
                    });
                }

                for (int i = 0; i < numThreads; i++)
                {
                    workerThreads[i].Start();
                    stopperThreads[i].Start();
                }

                for (int i = 0; i < numThreads; i++)
                {
                    workerThreads[i].Join();
                }

                Console.WriteLine("Усі потоки завершили роботу. Починаємо новий цикл.");
                Console.WriteLine();
            }
        }
    }

    class Worker
    {
        private int id;
        private int step;
        private int time;
        private volatile bool canStop = false;

        public Worker(int id, int step, int time)
        {
            this.id = id;
            this.step = step;
            this.time = time;
        }

        public void Stop()
        {
            canStop = true;
        }

        public void Calculate()
        {
            BigInteger sum = 0;
            BigInteger elementsCount = 0;
            BigInteger currentElement = 0;

            while (!canStop)
            {
                sum += currentElement;
                currentElement += step;
                elementsCount++;
            }

            Console.WriteLine($"{id} - {sum}, {step} - {elementsCount} разів за {time} сек.");
        }
    }
}