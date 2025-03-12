import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { AdoptPet } from '@/lib/contracts';
import { useSignAndExecuteTransaction, useCurrentAccount, useSuiClient } from '@mysten/dapp-kit';
import { networkConfig } from '@/networkConfig';

export function AdoptPetComponent() {
    const [petName, setPetName] = useState('');
    const [isAdopting, setIsAdopting] = useState(false);
    const { mutate: signAndExecuteTransaction } = useSignAndExecuteTransaction();
    const currentAccount = useCurrentAccount();
    const suiClient = useSuiClient();

    const handleAdopt = async () => {
        if (!petName.trim() || !currentAccount) {
            alert('請輸入寵物名稱並確保已連接錢包');
            return;
        }
        setIsAdopting(true);
        try {
            const userAddress = currentAccount.address;
            console.log('當前網絡配置:', networkConfig.testnet);
            console.log('當前網络:', networkConfig.testnet.url);
            console.log('合約ID:', networkConfig.testnet.packageID);
            console.log('State ID:', networkConfig.testnet.state);
            console.log('開始領養寵物，名稱：', petName);
            console.log('當前用戶地址：', userAddress);
            
            const tx = await AdoptPet(petName);
            console.log('交易區塊：', JSON.stringify(tx, null, 2));

            signAndExecuteTransaction({
                transaction: tx
            }, {
                onSuccess: async (result) => {
                    console.log('交易結果：', result);
                    
                    if (result.digest) {
                        console.log('交易哈希：', result.digest);
                        await suiClient.waitForTransaction({
                            digest: result.digest,
                        });

                        const txDetails = await suiClient.getTransactionBlock({
                            digest: result.digest,
                            options: {
                                showEvents: true,
                                showEffects: true,
                                showInput: true,
                            }
                        });
                        console.log('交易詳情：', txDetails);

                        // 檢查交易是否真的成功創建寵物
                        const events = txDetails.events;
                        if (!events || events.length === 0) {
                            alert('您已經擁有寵物了，不能重複領養');
                            throw new Error('未找到寵物創建事件，可能已經擁有寵物');
                        }

                        // 尋找 PetCreated 事件
                        const petCreatedEvent = events.find(
                            event => event.type.includes('::smart_contract::PetCreated')
                        );

                        if (!petCreatedEvent) {
                            alert('您已經擁有寵物了，不能重複領養');
                            throw new Error('寵物創建失敗，已經擁有寵物');
                        }

                        // 成功創建寵物
                        alert(`恭喜您成功領養了寵物：${petName}！\n請在控制台查看詳細信息`);
                        setPetName('');
                    }
                },
                onError: (error) => {
                    console.error("領養寵物失敗，詳細錯誤：", error);
                    alert("領養寵物失敗，請稍後再試");
                }
            });
            
        } catch (error: any) {
            console.error("領養寵物失敗：", error);
            console.error("錯誤詳情：", error.message);
            alert("領養寵物失敗，請稍後再試");
        } finally {
            setIsAdopting(false);
        }
    };

    if (!currentAccount) {
        return (
            <Card className="w-[400px]">
                <CardHeader>
                    <CardTitle>請先連接錢包</CardTitle>
                    <CardDescription>連接錢包後即可領養寵物</CardDescription>
                </CardHeader>
            </Card>
        );
    }

    return (
        <Card className="w-[400px]">
            <CardHeader>
                <CardTitle>領養寵物</CardTitle>
                <CardDescription>給您的寵物起個名字，開始您的番茄鐘之旅</CardDescription>
            </CardHeader>
            <CardContent>
                <form onSubmit={(e) => { e.preventDefault(); handleAdopt(); }}>
                    <div className="flex flex-col space-y-4">
                        <div className="flex flex-col space-y-1.5">
                            <Label htmlFor="petName">寵物名稱</Label>
                            <Input 
                                id="petName" 
                                placeholder="請輸入寵物名稱" 
                                value={petName}
                                onChange={(e) => setPetName(e.target.value)}
                            />
                        </div>
                        <div className="border-2 border-gray-300 rounded-lg h-[200px] flex items-center justify-center">
                            <img src="/src/images/Pumpkin.png" alt="寵物預覽" className="h-full object-contain" />
                        </div>
                    </div>
                </form>
            </CardContent>
            <CardFooter className="flex justify-end">
                <Button 
                    onClick={handleAdopt} 
                    disabled={!petName.trim() || isAdopting}
                >
                    {isAdopting ? '領養中...' : '領養寵物'}
                </Button>
            </CardFooter>
        </Card>
    );
}