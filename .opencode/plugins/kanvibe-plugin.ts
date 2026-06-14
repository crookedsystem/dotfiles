import type { Plugin } from "@opencode-ai/plugin";

/**
 * KanVibe OpenCode Plugin
 * message.updated(user) → progress, question.asked → pending,
 * question.replied → progress, session.idle → review 상태 변경
 */
export const KanvibePlugin: Plugin = async ({ $, client }) => {
  const KANVIBE_URL = "http://localhost:9736";
  const PROJECT_NAME = "dotfiles-main";

  async function getBranchName(): Promise<string | null> {
    try {
      const result = await $`git rev-parse --abbrev-ref HEAD`.quiet();
      const branch = result.text().trim();
      if (!branch || branch === "HEAD") return null;
      return branch;
    } catch {
      return null;
    }
  }

  async function updateStatus(status: string): Promise<void> {
    const branchName = await getBranchName();
    if (!branchName) return;

    try {
      await fetch(`${KANVIBE_URL}/api/hooks/status`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ branchName, projectName: PROJECT_NAME, status }),
      });
    } catch {
      /* 네트워크 에러 무시 */
    }
  }

  const sessionCache = new Map<string, boolean>();

  async function isMainSession(sessionID: string | undefined): Promise<boolean> {
    if (!sessionID) return false;
    if (sessionCache.has(sessionID)) return sessionCache.get(sessionID)!;

    try {
      const result = await client.session.get({
        path: { id: sessionID },
      });

      if (result.error) return false;

      const isMain = !result.data?.parentID;
      sessionCache.set(sessionID, isMain);

      return isMain;
    } catch {
      return false;
    }
  }

  return {
    event: async ({ event }) => {
      if (event.type === "message.updated") {
        const message =
          (event as any).properties?.info ?? (event as any).properties?.message;

        if (message?.role === "user" && (await isMainSession(message.sessionID))) {
          await updateStatus("progress");
        }
      }
      if (event.type === "question.asked") {
        if (!(await isMainSession(event.properties.sessionID))) {
          return;
        }

        await updateStatus("pending");
      }
      if (event.type === "question.replied") {
        if (!(await isMainSession(event.properties.sessionID))) {
          return;
        }

        await updateStatus("progress");
      }
      if (event.type === "session.idle") {
        if (!(await isMainSession(event.properties.sessionID))) {
          return;
        }

        await updateStatus("review");
      }
    },
  };
};
