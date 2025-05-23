import { Container } from "@radix-ui/themes";
import { PetComponent } from "../components/ui/PetComponent";
import type { Pet } from "../type";

function User() {
    // 測試用例 - 後續需要替換為真實數據
    const testPet: Pet = {
        id: "test-pet-1",
        name: "小花",
        owner: "0x123",
        hp: 100,
        level: 1
    };

    return (
        <Container>
            <Container
                mt="5"
                pt="2"
                px="4"
                style={{ 
                    background: "var(--gray-a2)", 
                    minHeight: 500,
                    display: "flex",
                    justifyContent: "center",
                    alignItems: "center"
                }}
            >
                <div style={{ display: "flex", justifyContent: "center", width: "100%" }}>
                    {testPet ? (
                        <PetComponent pet={testPet} />
                    ) : (
                        <div className="text-center">
                            你還沒有寵物，請先在首頁領養一隻寵物
                        </div>
                    )}
                </div>
            </Container>
        </Container>
    );
}

export default User;