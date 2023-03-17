import { Section } from '../components';
import { NtosWindow } from '../layouts';
import { useBackend } from '../backend';

export const SocialRating = (prop, context) => {
  const { act, data } = useBackend(context);
  const { Crewlist = {} } = data;
  return (
    <NtosWindow width={600} height={500}>
      <NtosWindow.Content scrollable>
        <Section title="Crew Ratings" />
        {modified}
      </NtosWindow.Content>
    </NtosWindow>
  );
};
