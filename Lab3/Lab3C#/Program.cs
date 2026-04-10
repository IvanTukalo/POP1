using System;
using System.Threading;

namespace Lab3Csharp
{
    class Program
    {
        private Semaphore accessMutex;
        private Semaphore emptySlots;
        private Semaphore filledSlots;

        private int currentStorageCount;
        private int globalConsumed;
        private int totalItems;
        private int numConsumers;

        static void Main(string[] args)
        {
            Thread.CurrentThread.CurrentCulture = new System.Globalization.CultureInfo("en-US");
            Console.OutputEncoding = System.Text.Encoding.UTF8;
            Console.ForegroundColor = ConsoleColor.Black;
            Console.BackgroundColor = ConsoleColor.White;
            Console.Clear();

            Program program = new Program();
            program.Run();
        }

        public void Run()
        {
            for (int j = 0; ;)
            {
                // Примусове обнулення стану перед кожним новим запуском
                currentStorageCount = 0;
                globalConsumed = 0;
                totalItems = 0;
                numConsumers = 0;

                int numProducers = 0;
                int capacity = 0;
                int[] producerItems = null;

                Console.WriteLine("Оберіть режим роботи (1 - Випадкова генерація, 2 - Ручне введення)");
                int mode = 1;
                while (true)
                {
                    if (int.TryParse(Console.ReadLine(), out mode) && (mode == 0 || mode == 1 || mode == 2))
                    {
                        break;
                    }
                    Console.WriteLine("Помилка вводу. Введіть 1 або 2.");
                }

                if (mode == 2)
                {
                    while (true)
                    {
                        Console.WriteLine("Введіть кількість Виробників, Споживачів та максимальну місткість сховища через пробіл");
                        string[] inputs = Console.ReadLine()?.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);

                        if (inputs != null && inputs.Length == 3 &&
                            int.TryParse(inputs[0], out numProducers) && numProducers > 0 &&
                            int.TryParse(inputs[1], out numConsumers) && numConsumers > 0 &&
                            int.TryParse(inputs[2], out capacity) && capacity > 0)
                        {
                            break;
                        }
                        Console.WriteLine("Помилка. Необхідно ввести три додатні цілі числа через пробіл.");
                    }

                    producerItems = new int[numProducers];
                    while (true)
                    {
                        Console.WriteLine($"Введіть кількість товарів яку створюватимуть Виробники в кількості {numProducers} через пробіл");
                        string[] itemsInput = Console.ReadLine()?.Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);

                        if (itemsInput != null && itemsInput.Length == numProducers)
                        {
                            bool allValid = true;
                            for (int i = 0; i < numProducers; i++)
                            {
                                if (!int.TryParse(itemsInput[i], out producerItems[i]) || producerItems[i] <= 0)
                                {
                                    allValid = false;
                                    break;
                                }
                            }

                            if (allValid)
                            {
                                break;
                            }
                        }
                        Console.WriteLine($"Помилка. Необхідно ввести рівно {numProducers} додатних цілих чисел.");
                    }
                }
                else if (mode == 0)
                {
                    return;
                }    
                else
                {
                    Random rnd = new Random();
                    numProducers = rnd.Next(1, 3);
                    numConsumers = rnd.Next(1, 3);
                    capacity = rnd.Next(3, 6);

                    producerItems = new int[numProducers];
                    for (int i = 0; i < numProducers; i++)
                    {
                        producerItems[i] = rnd.Next(6, 11);
                    }
                }

                for (int i = 0; i < numProducers; i++)
                {
                    totalItems += producerItems[i];
                }

                Console.WriteLine();
                Console.WriteLine($"Вмістимість сховища - {capacity}");
                Console.WriteLine($"Кількість споживачів - {numConsumers}");
                Console.WriteLine($"Загальна кількість товарів що будуть створені і спожиті - {totalItems}");
                for (int i = 0; i < numProducers; i++)
                {
                    Console.WriteLine($"{i + 1} виробник - {producerItems[i]} товарів");
                }
                Console.WriteLine();

                accessMutex = new Semaphore(1, 1);
                emptySlots = new Semaphore(capacity, capacity);
                filledSlots = new Semaphore(0, capacity);

                Thread[] producers = new Thread[numProducers];
                for (int i = 0; i < numProducers; i++)
                {
                    int localIndex = i + 1;
                    int itemsToProduce = producerItems[i];
                    producers[i] = new Thread(() => Produce(localIndex, itemsToProduce));
                    producers[i].Start();
                }

                Thread[] consumers = new Thread[numConsumers];
                for (int i = 0; i < numConsumers; i++)
                {
                    int localIndex = i + 1;
                    consumers[i] = new Thread(() => Consume(localIndex));
                    consumers[i].Start();
                }

                for (int i = 0; i < numProducers; i++)
                {
                    producers[i].Join();
                }
                for (int i = 0; i < numConsumers; i++)
                {
                    consumers[i].Join();
                }

                Console.WriteLine("Усі потоки успішно завершили роботу.\n");
            }
        }

        private void Produce(int producerIndex, int itemsToProduce)
        {
            int personalProduced = 0;
            while (personalProduced < itemsToProduce)
            {
                emptySlots.WaitOne();
                accessMutex.WaitOne();

                currentStorageCount++;
                personalProduced++;

                if (personalProduced == itemsToProduce)
                {
                    Console.WriteLine($"{producerIndex} Виробник завершив свою роботу, створено {personalProduced} товарів, заповненість {currentStorageCount}");
                }
                else
                {
                    Console.WriteLine($"{producerIndex} Виробник поклав свій {personalProduced} товар на склад, заповненість {currentStorageCount}");
                }

                accessMutex.Release();
                filledSlots.Release();
            }
        }

        private void Consume(int consumerIndex)
        {
            int personalConsumed = 0;
            while (true)
            {
                filledSlots.WaitOne();
                accessMutex.WaitOne();

                if (globalConsumed >= totalItems)
                {
                    accessMutex.Release();
                    filledSlots.Release();
                    break;
                }

                currentStorageCount--;
                globalConsumed++;
                personalConsumed++;

                Console.WriteLine($"{consumerIndex} Споживач спожив свій {personalConsumed} товар на складі, заповненість {currentStorageCount}");

                bool finishedAll = (globalConsumed == totalItems);

                accessMutex.Release();
                emptySlots.Release();

                if (finishedAll)
                {
                    filledSlots.Release(numConsumers);
                    break;
                }
            }
        }
    }
}