// 엔진 부팅 세대 — 겹친 boot() 는 이전 세대를 무효로 두고 하나만 살린다.
export class BootTicket {
  private gen = 0;

  issue(): number {
    this.gen += 1;
    return this.gen;
  }

  isLive(g: number): boolean {
    return g === this.gen;
  }

  invalidate(): void {
    this.gen += 1;
  }
}
