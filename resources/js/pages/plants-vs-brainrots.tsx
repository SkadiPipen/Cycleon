import { useEffect, useState } from "react";
import { H2 } from '@/components/h2';
import { H3 } from '@/components/h3';
import { H4 } from '@/components/h4';
import { PlaceholderPattern } from '@/components/ui/placeholder-pattern';
import AppLayout from '@/layouts/app-layout';
import { plantsVsBrainrots } from '@/routes';
import { type BreadcrumbItem } from '@/types';
import { Head } from '@inertiajs/react';
import StockCard from "@/components/stock-card";
import WeatherCard from "@/components/weather-card";
import { useRefreshCountdown } from "@/hooks/use-refresh-countdown";
import { Zap, Cloud, CloudRain, CloudSnow, Sun, Thermometer, Wind } from "lucide-react";

const breadcrumbs: BreadcrumbItem[] = [
    {
        title: 'Plants vs Brainrots',
        href: plantsVsBrainrots().url,
    },
];

interface SeedItem {
    Name: string;
    Stock: number;
    Image: string;
    Price: number;
}

interface GearItem {
    Name: string;
    Stock: number;
    Image: string;
    Price: number;
    Rarity: string;
    Description: string;
    Fuel: number;
}

interface SeasonItem {
    Name: string;
    Stock: number;
}

interface ChristmasItem {
    Name: string;
    Stock: number;
}

interface LastSeenItem {
    Name: string;
    Stock: number;
    Image: string;
    LastSeen: number;
}

interface WeatherEvent {
    Name: string;
    DisplayName: string;
    Image: string;
    Description: string;
    LastSeen: number;
    Type?: 'weather' | 'event';
}

interface NextEvent {
    UNIX_TimeStamp_Ended: number;
    Image: string;
    Name: string;
    UNIX_TimeStamp_StartIn: number;
    Description: string;
    DisplayName: string;
}

interface PlantsVsBrainrotsData {
    Seed_Stock: SeedItem[];
    Gear_Stock: GearItem[];
    Season_stock: SeasonItem[];
    Christmas_stock: ChristmasItem[];
    LastSeen: LastSeenItem[];
}

interface EventsData {
    events: WeatherEvent[];
    lastSeenEvents: WeatherEvent[];
    nextEvent: NextEvent | null;
    timestamp: string;
}


const calculateRestockTimes = (intervalMinutes: number): { lastRestock: string; nextRestock: string } => {
    const now = new Date();
    const intervalMs = intervalMinutes * 60 * 1000;

    const midnight = new Date(now);
    midnight.setHours(0, 0, 0, 0);

    const timeSinceMidnight = now.getTime() - midnight.getTime();
    const intervalsSinceMidnight = Math.floor(timeSinceMidnight / intervalMs);

    const lastRestockTime = new Date(midnight.getTime() + (intervalsSinceMidnight * intervalMs));
    const nextRestockTime = new Date(lastRestockTime.getTime() + intervalMs);

    const formatTime = (date: Date) => {
        return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    };

    return {
        lastRestock: formatTime(lastRestockTime),
        nextRestock: formatTime(nextRestockTime)
    };
};

const timeAgo = (timestamp: number) => {
    const now = Math.floor(Date.now() / 1000);
    const diff = now - timestamp;

    if (diff < 60) return 'just now';
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    return `${Math.floor(diff / 86400)}d ago`;
};


const useEventCountdown = (timestamp: number | undefined | null) => {
    const [countdown, setCountdown] = useState<string>("No event");

    useEffect(() => {
        if (!timestamp) {
            setCountdown("No event");
            return;
        }

        const calculateCountdown = () => {
            const now = Math.floor(Date.now() / 1000);
            const diff = timestamp - now;

            if (diff <= 0) {
                setCountdown("Started");
                return;
            }

            const hours = Math.floor(diff / 3600);
            const minutes = Math.floor((diff % 3600) / 60);
            const seconds = diff % 60;

            if (hours > 0) {
                setCountdown(`${hours}h ${minutes}m`);
            } else if (minutes > 0) {
                setCountdown(`${minutes}m ${seconds}s`);
            } else {
                setCountdown(`${seconds}s`);
            }
        };

        calculateCountdown();
        const interval = setInterval(calculateCountdown, 1000);
        return () => clearInterval(interval);
    }, [timestamp]);

    return countdown;
};

export default function PlantsVsBrainrots() {
    const [stockData, setStockData] = useState<PlantsVsBrainrotsData | null>(null);
    const [eventsData, setEventsData] = useState<EventsData | null>(null);
    const [loading, setLoading] = useState(true);

    // Calculate restock times
    const seedRestock = calculateRestockTimes(5);
    const gearRestock = calculateRestockTimes(5);
    const seasonRestock = calculateRestockTimes(30);
    const christmasRestock = calculateRestockTimes(240);
    const lastSeenRestock = calculateRestockTimes(60);

    // Use your refresh countdown hook
    const seedCountdown = useRefreshCountdown("00:00", 5);
    const gearCountdown = useRefreshCountdown("00:00", 5);
    const seasonCountdown = useRefreshCountdown("00:00", 30);
    const christmasCountdown = useRefreshCountdown("00:00", 240);
    const lastSeenCountdown = useRefreshCountdown("00:00", 60);

    // Countdown for next event - FIXED: Always call hook, handle null inside
    const nextEventCountdown = useEventCountdown(
        eventsData?.nextEvent?.UNIX_TimeStamp_StartIn
    );

    useEffect(() => {
        const fetchStock = async () => {
            try {
                const res = await fetch('/proxy/stock/plants-vs-brainrots');
                if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
                const data = await res.json();
                setStockData(data);
            } catch (error) {
                console.error("Failed to fetch stock:", error);
                setStockData(null);
            }
        };

        fetchStock();
        const interval = setInterval(fetchStock, 60_000);
        return () => clearInterval(interval);
    }, []);

    useEffect(() => {
        const fetchEvents = async () => {
            try {
                const res = await fetch('/proxy/events/plants-vs-brainrots');
                if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
                const data = await res.json();
                setEventsData(data);
            } catch (error) {
                console.error("Failed to fetch events:", error);
                setEventsData(null);
            } finally {
                setLoading(false);
            }
        };

        fetchEvents();
        const interval = setInterval(fetchEvents, 60_000);
        return () => clearInterval(interval);
    }, []);

    // Convert data to StockCard format
    const convertToStockCardItems = (items: any[]): any[] => {
        if (!items) return [];

        return items.map(item => ({
            name: item.Name || item.name || 'Unknown',
            Stock: item.Stock || item.stock || 0,
            image: item.Image || item.image || '',
            Tier: item.Rarity || item.Tier,
            Price: item.Price || item.price
        }));
    };

    // Get weather events (filter from all events)
    const weatherEvents = eventsData?.lastSeenEvents?.filter(event => {
        const name = event.Name.toLowerCase();
        return name.includes('storm') || name.includes('rain') || name.includes('snow') ||
            name.includes('heat') || name.includes('sun') || name.includes('fog') ||
            name.includes('wind') || name.includes('icy') || name.includes('frozen');
    }) || [];

    // Convert events to WeatherCard format
    const weatherCardItems = eventsData?.lastSeenEvents?.map(event => ({
        Name: event.Name,
        DisplayName: event.DisplayName,
        Image: event.Image,
        Description: event.Description,
        LastSeen: event.LastSeen,
        start_timestamp_unix: event.LastSeen,
        end_timestamp_unix: event.LastSeen + 3600
    })) || [];

    return (
        <AppLayout breadcrumbs={breadcrumbs} data-theme="green">
            <Head title="Plants vs Brainrots" />
            <div className="flex h-full flex-1 flex-col gap-4 overflow-x-auto rounded-xl p-4 bg-transparent">
                <div className="flex flex-col items-center justify-center w-full my-16 leading-none bg-transparent">
                    <H3>
                        Stocks and Events Live Tracking and Forecast for
                    </H3>
                    <H2 className="text-sidebar-primary">
                        Plants Vs. Brainrots
                    </H2>
                </div>

                <H4>
                    Live Stocks
                </H4>

                {loading ? (
                    <div className="grid auto-rows-min gap-4 md:grid-cols-3 bg-transparent">
                        {[1, 2, 3, 4, 5].map(i => (
                            <div key={i} className="bg-background/20 p-4 rounded-lg animate-pulse">
                                <div className="h-6 bg-gray-300 dark:bg-gray-700 rounded mb-4"></div>
                                <div className="h-4 bg-gray-200 dark:bg-gray-800 rounded mb-2"></div>
                                <div className="h-4 bg-gray-200 dark:bg-gray-800 rounded mb-6"></div>
                                <div className="h-64 bg-gray-100 dark:bg-gray-900 rounded"></div>
                            </div>
                        ))}
                    </div>
                ) : (
                    <>
                        <div className="grid auto-rows-min gap-4 md:grid-cols-3 bg-transparent">
                            {/* Seed Shop */}
                            <StockCard
                                title="Seed Shop"
                                items={convertToStockCardItems(stockData?.Seed_Stock || [])}
                                lastRestock={seedRestock.lastRestock}
                                nextRestock={seedRestock.nextRestock}
                                countdown={seedCountdown}
                                intervalMinutes={5}
                            />

                            {/* Gear Shop */}
                            <StockCard
                                title="Gear Shop"
                                items={convertToStockCardItems(stockData?.Gear_Stock || [])}
                                lastRestock={gearRestock.lastRestock}
                                nextRestock={gearRestock.nextRestock}
                                countdown={gearCountdown}
                                intervalMinutes={5}
                            />

                            {/* Season Stock */}
                            <StockCard
                                title="Season Stock"
                                items={convertToStockCardItems(stockData?.Season_stock || [])}
                                lastRestock={seasonRestock.lastRestock}
                                nextRestock={seasonRestock.nextRestock}
                                countdown={seasonCountdown}
                                intervalMinutes={30}
                            />

                            {/* Christmas Stock */}
                            <StockCard
                                title="Christmas Stock"
                                items={convertToStockCardItems(stockData?.Christmas_stock || [])}
                                lastRestock={christmasRestock.lastRestock}
                                nextRestock={christmasRestock.nextRestock}
                                countdown={christmasCountdown}
                                intervalMinutes={240}
                            />

                            {/* Last Seen Items */}
                            <StockCard
                                title="Recently Seen"
                                items={convertToStockCardItems(stockData?.LastSeen || [])}
                                lastRestock={lastSeenRestock.lastRestock}
                                nextRestock={lastSeenRestock.nextRestock}
                                countdown={lastSeenCountdown}
                                intervalMinutes={60}
                            />

                            {/* Next Event Card */}
                            {eventsData?.nextEvent && (
                                <div className="bg-background/20 p-6 rounded-lg border border-sidebar-border/50">
                                    <div className="flex items-center gap-3 mb-4">
                                        <Zap className="h-5 w-5 text-yellow-500" />
                                        <div>
                                            <div className="font-semibold">Next Event</div>
                                            <div className="text-sm text-gray-500">Starting soon</div>
                                        </div>
                                    </div>

                                    <div className="flex items-center gap-3 mb-4">
                                        {eventsData.nextEvent.Image &&
                                        (eventsData.nextEvent.Image.startsWith('http://') ||
                                            eventsData.nextEvent.Image.startsWith('https://')) ? (
                                            <img
                                                src={eventsData.nextEvent.Image}
                                                alt={eventsData.nextEvent.DisplayName}
                                                className="w-12 h-12 rounded-lg object-cover"
                                                onError={(e) => {
                                                    // Hide the image if it fails to load
                                                    e.currentTarget.style.display = 'none';
                                                }}
                                            />
                                        ) : (
                                            <div className="w-12 h-12 rounded-lg bg-yellow-100 flex items-center justify-center">
                                                <Zap className="h-6 w-6 text-yellow-600" />
                                            </div>
                                        )}
                                        <div>
                                            <div className="font-medium">{eventsData.nextEvent.DisplayName}</div>
                                            <div className="text-sm text-gray-500">
                                                Starts in: {nextEventCountdown}
                                            </div>
                                        </div>
                                    </div>

                                    <div className="text-sm text-gray-600 dark:text-gray-400">
                                        {eventsData.nextEvent.Description}
                                    </div>
                                </div>
                            )}
                        </div>

                        {/* Weather Events Card */}
                        {weatherCardItems.length > 0 && (
                            <>
                                <H4 className="mt-8">
                                    All Events
                                </H4>
                                <WeatherCard
                                    title="Events & Weather"
                                    items={weatherCardItems}
                                    className="col-span-3"
                                />
                            </>
                        )}
                    </>
                )}

                <H4 className="mt-20">
                    Events Forecast
                </H4>
                <div className="relative min-h-[100vh] flex-1 overflow-hidden rounded-xl border border-sidebar-border/70 md:min-h-min dark:border-sidebar-border bg-transparent">
                    <PlaceholderPattern className="absolute inset-0 size-full stroke-neutral-900/20 dark:stroke-neutral-100/20" />
                </div>
            </div>
        </AppLayout>
    );
}
