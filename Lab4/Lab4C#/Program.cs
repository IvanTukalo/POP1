using System;
using System.Threading;

namespace Lab4Csharp
{
    class Program
    {
        static void Main(string[] args)
        {
            Thread.CurrentThread.CurrentCulture = new System.Globalization.CultureInfo("en-US");
            Console.OutputEncoding = System.Text.Encoding.UTF8;
            Console.ForegroundColor = ConsoleColor.Black;
            Console.BackgroundColor = ConsoleColor.White;
            Console.Clear(); Program program = new Program();
            program.Run();
        }

        public void Run()
        {
            while (true)
            {
                Console.WriteLine("Оберіть метод вирішення проблеми взаємного блокування");
                Console.WriteLine("1 - Асиметричний філософ (зміна порядку вилок для 5-го)");
                Console.WriteLine("2 - Обмеження доступу (не більше 4 філософів за столом)");
                Console.WriteLine("3 - Офіціанти (лише 2 філософи можуть їсти одночасно)");
                Console.WriteLine("4 - Відмова від очікування (покласти вилку, якщо друга зайнята)");
                Console.WriteLine("0 - Вихід");

                int mode;
                while (true)
                {
                    if (int.TryParse(Console.ReadLine(), out mode) && mode >= 0 && mode <= 4)
                    {
                        break;
                    }
                    Console.WriteLine("Помилка вводу. Введіть число від 0 до 4.");
                }

                if (mode == 0)
                {
                    return;
                }

                Console.WriteLine($"\nЗапуск Рішення {mode} (15 ітерацій)...\n");
                for (int test = 1; test <= 15; test++)
                {
                    Console.WriteLine($"--- Ітерація {test} ---");

                    if (mode == 1) RunAsymmetricPhilosopher();
                    else if (mode == 2) RunLimitedAccess();
                    else if (mode == 3) RunWaiters();
                    else if (mode == 4) RunTryLock();

                    Console.WriteLine($"--- Ітерація {test} успішно завершена ---\n");
                }
            }
        }

        private void RunAsymmetricPhilosopher()
        {
            int numPhilosophers = 5;
            Semaphore[] forks = new Semaphore[numPhilosophers];
            for (int i = 0; i < numPhilosophers; i++)
            {
                forks[i] = new Semaphore(1, 1);
            }

            Semaphore completionSemaphore = new Semaphore(0, numPhilosophers);

            for (int i = 0; i < numPhilosophers; i++)
            {
                int localId = i;
                new Thread(() => TaskAsymmetric(localId, forks, completionSemaphore)).Start();
            }

            for (int i = 0; i < numPhilosophers; i++)
            {
                completionSemaphore.WaitOne();
            }
        }

        private void TaskAsymmetric(int id, Semaphore[] forks, Semaphore completionSemaphore)
        {
            try
            {
                int rightFork = id;
                int leftFork = (id + 1) % 5;

                for (int i = 0; i < 10; i++)
                {
                    Console.WriteLine($"Філософ {id + 1} думає {i + 1} раз");
                    Thread.Sleep(10);

                    if (id == 4)
                    {
                        forks[leftFork].WaitOne();
                        forks[rightFork].WaitOne();
                    }
                    else
                    {
                        forks[rightFork].WaitOne();
                        forks[leftFork].WaitOne();
                    }

                    Console.WriteLine($"Філософ {id + 1} їсть {i + 1} раз");

                    if (id == 4)
                    {
                        forks[rightFork].Release();
                        forks[leftFork].Release();
                    }
                    else
                    {
                        forks[leftFork].Release();
                        forks[rightFork].Release();
                    }
                }
            }
            finally
            {
                completionSemaphore.Release();
            }
        }

        private void RunLimitedAccess()
        {
            int numPhilosophers = 5;
            Semaphore[] forks = new Semaphore[numPhilosophers];
            for (int i = 0; i < numPhilosophers; i++)
            {
                forks[i] = new Semaphore(1, 1);
            }

            Semaphore completionSemaphore = new Semaphore(0, numPhilosophers);
            Semaphore limitSemaphore = new Semaphore(numPhilosophers - 1, numPhilosophers - 1);

            for (int i = 0; i < numPhilosophers; i++)
            {
                int localId = i;
                new Thread(() => TaskWithLimit(localId, forks, completionSemaphore, limitSemaphore)).Start();
            }

            for (int i = 0; i < numPhilosophers; i++)
            {
                completionSemaphore.WaitOne();
            }
        }

        private void TaskWithLimit(int id, Semaphore[] forks, Semaphore completionSemaphore, Semaphore limitSemaphore)
        {
            try
            {
                int rightFork = id;
                int leftFork = (id + 1) % 5;

                for (int i = 0; i < 10; i++)
                {
                    Console.WriteLine($"Філософ {id + 1} думає {i + 1} раз");
                    Thread.Sleep(10);

                    limitSemaphore.WaitOne();
                    forks[rightFork].WaitOne();
                    forks[leftFork].WaitOne();

                    Console.WriteLine($"Філософ {id + 1} їсть {i + 1} раз");

                    forks[leftFork].Release();
                    forks[rightFork].Release();
                    limitSemaphore.Release();
                }
            }
            finally
            {
                completionSemaphore.Release();
            }
        }

        private void RunWaiters()
        {
            int numPhilosophers = 5;
            Semaphore[] forks = new Semaphore[numPhilosophers];
            for (int i = 0; i < numPhilosophers; i++)
            {
                forks[i] = new Semaphore(1, 1);
            }

            Semaphore completionSemaphore = new Semaphore(0, numPhilosophers);
            Semaphore waitersSemaphore = new Semaphore(2, 2);

            for (int i = 0; i < numPhilosophers; i++)
            {
                int localId = i;
                new Thread(() => TaskWithWaiters(localId, forks, completionSemaphore, waitersSemaphore)).Start();
            }

            for (int i = 0; i < numPhilosophers; i++)
            {
                completionSemaphore.WaitOne();
            }
        }

        private void TaskWithWaiters(int id, Semaphore[] forks, Semaphore completionSemaphore, Semaphore waitersSemaphore)
        {
            try
            {
                int rightFork = id;
                int leftFork = (id + 1) % 5;

                for (int i = 0; i < 10; i++)
                {
                    Console.WriteLine($"Філософ {id + 1} думає {i + 1} раз");
                    Thread.Sleep(10);

                    waitersSemaphore.WaitOne();
                    forks[rightFork].WaitOne();
                    forks[leftFork].WaitOne();

                    Console.WriteLine($"Філософ {id + 1} їсть {i + 1} раз");

                    forks[leftFork].Release();
                    forks[rightFork].Release();
                    waitersSemaphore.Release();
                }
            }
            finally
            {
                completionSemaphore.Release();
            }
        }

        private void RunTryLock()
        {
            int numPhilosophers = 5;
            Semaphore[] forks = new Semaphore[numPhilosophers];
            for (int i = 0; i < numPhilosophers; i++)
            {
                forks[i] = new Semaphore(1, 1);
            }

            Semaphore completionSemaphore = new Semaphore(0, numPhilosophers);

            for (int i = 0; i < numPhilosophers; i++)
            {
                int localId = i;
                new Thread(() => TaskTryLock(localId, forks, completionSemaphore)).Start();
            }

            for (int i = 0; i < numPhilosophers; i++)
            {
                completionSemaphore.WaitOne();
            }
        }

        private void TaskTryLock(int id, Semaphore[] forks, Semaphore completionSemaphore)
        {
            try
            {
                int rightFork = id;
                int leftFork = (id + 1) % 5;

                for (int i = 0; i < 10; i++)
                {
                    Console.WriteLine($"Філософ {id + 1} думає {i + 1} раз");
                    Thread.Sleep(10);

                    while (true)
                    {
                        forks[rightFork].WaitOne();

                        if (forks[leftFork].WaitOne(0))
                        {
                            break;
                        }
                        else
                        {
                            forks[rightFork].Release();
                            Thread.Sleep(5);
                        }
                    }

                    Console.WriteLine($"Філософ {id + 1} їсть {i + 1} раз");

                    forks[leftFork].Release();
                    forks[rightFork].Release();
                }
            }
            finally
            {
                completionSemaphore.Release();
            }
        }
    }
}