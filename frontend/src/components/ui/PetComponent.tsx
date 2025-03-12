import { Pet } from '@/type';
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useState } from 'react';

type PetComponentProps = {
    pet: Pet;
}

// 测试用例
const testPet: Pet = {
    id: "test-pet-1",
    name: "小花",
    owner: "0x123", 
    hp: 100,
    level: 1
}

export function PetComponent({ pet }: PetComponentProps) {
    const [timerActive, setTimerActive] = useState(false);
    const [timeLeft, setTimeLeft] = useState(25 * 60); // 25分钟，以秒为单位

    // 格式化时间显示
    const formatTime = (seconds: number) => {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
    };

    // 开始5分钟计时
    const startShortTimer = () => {
        setTimeLeft(5 * 60);
        setTimerActive(true);
    };

    return (
        <Card className="w-[800px] p-6">
            <CardContent className="p-0 flex flex-row gap-8">
                {/* 左侧宠物信息 */}
                <div className="flex-1">
                    <div className="border-2 border-gray-300 rounded-lg h-[300px] mb-6 flex items-center justify-center">
                        <img src="/src/images/Pumpkin.png" alt="宠物图片" className="max-h-full max-w-full object-contain" />
                    </div>
                    
                    <div className="space-y-4">
                        <div>
                            <p className="text-lg mb-1">HP</p>
                            <div className="w-full h-2 bg-gray-200 rounded-full">
                                <div 
                                    className="h-2 bg-green-500 rounded-full" 
                                    style={{ width: `${pet.hp}%` }}
                                ></div>
                            </div>
                        </div>
                        
                        <div>
                            <p className="text-lg mb-1">Level</p>
                            <div className="w-full h-2 bg-gray-200 rounded-full">
                                <div 
                                    className="h-2 bg-blue-500 rounded-full" 
                                    style={{ width: `${pet.level * 10}%` }}
                                ></div>
                            </div>
                        </div>
                    </div>
                </div>
                
                {/* 右侧番茄钟 */}
                <div className="flex-1 flex flex-col items-center">
                    <div className="border-2 border-gray-300 rounded-full w-[250px] h-[250px] mb-6 flex items-center justify-center">
                        <p className="text-2xl">{formatTime(timeLeft)}</p>
                    </div>
                    
                    <div className="grid grid-cols-2 gap-4 w-full">
                        <Button 
                            onClick={startShortTimer}
                            className="h-12"
                        >
                            5分钟
                        </Button>
                        <Button 
                            onClick={() => {
                                setTimeLeft(15 * 60);
                                setTimerActive(true);
                            }}
                            className="h-12"
                            variant="outline"
                        >
                            15分钟
                        </Button>
                        <Button 
                            onClick={() => {
                                setTimeLeft(25 * 60);
                                setTimerActive(true);
                            }}
                            className="h-12"
                            variant="outline"
                        >
                            25分钟
                        </Button>
                        <Button 
                            onClick={() => {
                                setTimerActive(false);
                            }}
                            className="h-12"
                            variant="outline"
                        >
                            停止
                        </Button>
                    </div>
                </div>
            </CardContent>
            <div className="text-sm text-gray-500 mt-2">
                寵物 ID: {pet.id}
            </div>
        </Card>
    );
}