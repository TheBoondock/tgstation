import { Section, Button, Box } from '../components';
import { NtosWindow } from '../layouts';

export const SocialRating = (prop, context) => {
  return (
    <NtosWindow width={600} height={500}>
      <NtosWindow.Content scrollable>
        <Section
          title="Something"
          button={<Button icon="anything" content="anything" />}>
          <Box> placeholder text </Box>
        </Section>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
